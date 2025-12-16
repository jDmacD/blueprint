#!/usr/bin/env bash
#
# cleanup-boot-partition.sh - Clean up Raspberry Pi boot partitions (AGGRESSIVE)
#
# This script removes temporary files, old NixOS generations, and stale boot
# files to free up space on the /boot/firmware partition.
#
# AGGRESSIVE MODE: Deletes ALL old generations, keeps only the current one.
# WARNING: You will not be able to rollback to previous generations!
#
# Usage:
#   ./cleanup-boot-partition.sh [hostname]
#
# If hostname is provided, runs cleanup on that remote host via SSH.
# Otherwise, runs cleanup on the local system.

set -euo pipefail

HOSTNAME="${1:-}"
BOOT_PATH="/boot/firmware"
SSH_USER="jmacdonald"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Function to run command (either locally or via SSH)
run_cmd() {
    if [[ -n "$HOSTNAME" ]]; then
        ssh "${SSH_USER}@${HOSTNAME}" "$@"
    else
        eval "$@"
    fi
}

# Function to run command with sudo (either locally or via SSH)
run_sudo() {
    if [[ -n "$HOSTNAME" ]]; then
        ssh "${SSH_USER}@${HOSTNAME}" "sudo $*"
    else
        sudo bash -c "$*"
    fi
}

main() {
    local target="${HOSTNAME:-localhost}"

    echo "========================================"
    echo "Boot Partition Cleanup for: $target"
    echo "========================================"
    log_warn "AGGRESSIVE MODE: This will delete ALL old generations!"
    log_warn "You will NOT be able to rollback after this cleanup."
    echo

    # Check disk space before cleanup
    log_info "Boot partition usage BEFORE cleanup:"
    run_cmd "df -h $BOOT_PATH"
    echo

    # Step 1: Remove temporary files
    log_info "Removing temporary files from $BOOT_PATH..."
    run_sudo "rm -rf $BOOT_PATH/*.tmp* $BOOT_PATH/nixos/*.tmp.* 2>/dev/null || true"
    log_info "Temporary files removed."
    echo

    # Step 2: Delete ALL old NixOS generations (AGGRESSIVE - keeps only current)
    log_warn "AGGRESSIVE MODE: Deleting ALL old NixOS generations..."
    run_sudo "nix-collect-garbage -d"
    echo

    # Step 3: List current generations
    log_info "Current system generations:"
    run_sudo "nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 5"
    echo

    # Step 4: Clean up old boot generation directories (AGGRESSIVE - keep only 1)
    log_warn "AGGRESSIVE MODE: Keeping only the most recent boot generation..."
    if [[ -n "$HOSTNAME" ]]; then
        # For remote execution, we need a more complex command
        ssh "${SSH_USER}@${HOSTNAME}" 'sudo bash -c '"'"'
            cd '"$BOOT_PATH"'/nixos 2>/dev/null || exit 0

            # List all generation directories (sorted by name)
            GENS=$(ls -1d *-default 2>/dev/null | sort -V || true)

            if [[ -z "$GENS" ]]; then
                echo "No generation directories found"
                exit 0
            fi

            # Count total generations
            TOTAL=$(echo "$GENS" | wc -l)

            # Keep only last 1 generation, delete everything else
            if [[ $TOTAL -gt 1 ]]; then
                TO_DELETE=$(echo "$GENS" | head -n -1)
                for gen in $TO_DELETE; do
                    echo "Removing old generation: $gen"
                    rm -rf "$gen"
                done
                echo "Removed $((TOTAL - 1)) old generation(s), kept 1"
            else
                echo "Only $TOTAL generation(s) found, keeping it"
            fi
        '"'"
    else
        # Local execution
        sudo bash -c '
            cd '"$BOOT_PATH"'/nixos 2>/dev/null || exit 0
            GENS=$(ls -1d *-default 2>/dev/null | sort -V || true)

            if [[ -z "$GENS" ]]; then
                echo "No generation directories found"
                exit 0
            fi

            TOTAL=$(echo "$GENS" | wc -l)

            if [[ $TOTAL -gt 1 ]]; then
                TO_DELETE=$(echo "$GENS" | head -n -1)
                for gen in $TO_DELETE; do
                    echo "Removing old generation: $gen"
                    rm -rf "$gen"
                done
                echo "Removed $((TOTAL - 1)) old generation(s), kept 1"
            else
                echo "Only $TOTAL generation(s) found, keeping it"
            fi
        '
    fi
    echo

    # Step 5: Run garbage collection again to ensure everything is cleaned
    log_info "Running final garbage collection..."
    run_sudo "nix-store --gc 2>/dev/null || true"
    echo

    # Step 5b: Optimize Nix store (hard-link identical files)
    log_info "Optimizing Nix store to recover space..."
    run_sudo "nix-store --optimise 2>/dev/null || true"
    echo

    # Step 6: Check disk space after cleanup
    log_info "Boot partition usage AFTER cleanup:"
    run_cmd "df -h $BOOT_PATH"
    echo

    # Check if we have enough free space (recommend 40MB+)
    AVAIL=$(run_cmd "df -BM $BOOT_PATH | tail -1 | awk '{print \$4}' | sed 's/M//'")
    if [[ $AVAIL -lt 10 ]]; then
        log_error "WARNING: Less than 10MB free! Manual intervention may be required."
        return 1
    elif [[ $AVAIL -lt 40 ]]; then
        log_warn "WARNING: Less than 40MB free. Consider rebuilding with a larger boot partition."
    else
        log_info "Cleanup successful! ${AVAIL}MB available."
    fi

    echo
    echo "========================================"
    echo "Cleanup complete for: $target"
    echo "========================================"
}

# Run main function
main
