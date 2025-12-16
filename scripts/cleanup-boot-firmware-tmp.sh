#!/usr/bin/env bash
#
# cleanup-boot-firmware-tmp.sh - Clean temporary files from /boot/firmware
#
# This script removes only temporary and duplicate files from /boot/firmware,
# which are left behind by failed deployment attempts. This is less aggressive
# than clearing the entire partition.
#
# Usage:
#   ./cleanup-boot-firmware-tmp.sh [hostname]
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
    echo "Boot Firmware Cleanup for: $target"
    echo "========================================"
    echo

    # Check disk space before cleanup
    log_info "Boot partition usage BEFORE cleanup:"
    run_cmd "df -h $BOOT_PATH"
    echo

    # Step 1: Remove all .tmp files
    log_info "Removing temporary files (*.tmp*)..."
    REMOVED=$(run_sudo "find $BOOT_PATH -name '*.tmp*' -type f -exec ls -lh {} \; 2>/dev/null || true")
    if [[ -n "$REMOVED" ]]; then
        echo "$REMOVED"
        run_sudo "find $BOOT_PATH -name '*.tmp*' -type f -delete 2>/dev/null || true"
        log_info "Temporary files removed"
    else
        log_info "No temporary files found"
    fi
    echo

    # Step 2: Remove old armstub files (if present from very old dates)
    log_info "Checking for old armstub files..."
    ARMSTUB=$(run_sudo "find $BOOT_PATH -name 'armstub*' -type f 2>/dev/null || true")
    if [[ -n "$ARMSTUB" ]]; then
        log_warn "Found armstub files (may be old):"
        run_sudo "ls -lh $BOOT_PATH/armstub* 2>/dev/null || true"
        log_info "Leaving armstub files (remove manually if needed)"
    fi
    echo

    # Step 3: Check for duplicate u-boot files
    log_info "Checking for multiple u-boot files..."
    UBOOT_FILES=$(run_sudo "ls -lh $BOOT_PATH/u-boot*.bin 2>/dev/null || echo 'None found'")
    echo "$UBOOT_FILES"
    log_info "Multiple u-boot files are normal (different RPi models)"
    echo

    # Step 4: Check disk space after cleanup
    log_info "Boot partition usage AFTER cleanup:"
    run_cmd "df -h $BOOT_PATH"
    echo

    # Check if we have enough free space
    AVAIL=$(run_cmd "df -BM $BOOT_PATH | tail -1 | awk '{print \$4}' | sed 's/M//'")
    if [[ $AVAIL -lt 3 ]]; then
        log_warn "WARNING: Less than 3MB free!"
        log_warn "Consider using deploy-rpi-clean.sh to fully clear and repopulate"
        return 1
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
