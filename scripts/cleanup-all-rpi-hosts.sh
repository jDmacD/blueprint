#!/usr/bin/env bash
#
# cleanup-all-rpi-hosts.sh - Clean up boot partitions on all Raspberry Pi hosts
#
# This script runs the boot partition cleanup across all Raspberry Pi hosts
# in the cluster.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup-boot-partition.sh"

# All Raspberry Pi hosts
RPI_HOSTS=(
    "pi01.lan"
    "pi02.lan"
    "pi03.lan"
    "pi04.lan"
    "pi05.lan"
    "tpi01.lan"
    "tpi02.lan"
    "tpi03.lan"
    "tpi04.lan"
)

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

main() {
    echo "========================================"
    echo "Cleaning up boot partitions on all RPi hosts"
    echo "========================================"
    echo

    if [[ ! -x "$CLEANUP_SCRIPT" ]]; then
        echo "ERROR: Cleanup script not found or not executable: $CLEANUP_SCRIPT"
        exit 1
    fi

    local failed_hosts=()

    for host in "${RPI_HOSTS[@]}"; do
        echo
        echo -e "${BLUE}================================================${NC}"
        echo -e "${BLUE}Processing: $host${NC}"
        echo -e "${BLUE}================================================${NC}"
        echo

        if "$CLEANUP_SCRIPT" "$host"; then
            echo "✓ $host - SUCCESS"
        else
            echo "✗ $host - FAILED"
            failed_hosts+=("$host")
        fi

        echo
        sleep 2  # Brief pause between hosts
    done

    echo
    echo "========================================"
    echo "Summary"
    echo "========================================"
    echo "Total hosts: ${#RPI_HOSTS[@]}"
    echo "Failed: ${#failed_hosts[@]}"

    if [[ ${#failed_hosts[@]} -gt 0 ]]; then
        echo
        echo "Failed hosts:"
        for host in "${failed_hosts[@]}"; do
            echo "  - $host"
        done
        exit 1
    else
        echo
        echo "All hosts cleaned successfully!"
    fi
}

main
