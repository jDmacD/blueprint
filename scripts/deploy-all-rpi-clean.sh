#!/usr/bin/env bash
#
# deploy-all-rpi-clean.sh - Deploy to all Raspberry Pi hosts with clean boot
#
# This script deploys to all RPi hosts using the clean boot partition method.
# Each host gets /boot/firmware cleared before deployment to prevent space issues.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-rpi-clean.sh"

# All Raspberry Pi hosts
RPI_HOSTS=(
    "pi01"
    "pi02"
    "pi03"
    "pi04"
    "pi05"
    "tpi01"
    "tpi02"
    "tpi03"
    "tpi04"
)

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

main() {
    echo "========================================"
    echo "Clean Boot Deployment to All RPi Hosts"
    echo "========================================"
    echo

    if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
        echo "ERROR: Deploy script not found or not executable: $DEPLOY_SCRIPT"
        exit 1
    fi

    local failed_hosts=()
    local successful_hosts=()

    for host in "${RPI_HOSTS[@]}"; do
        echo
        echo -e "${BLUE}================================================${NC}"
        echo -e "${BLUE}Processing: $host${NC}"
        echo -e "${BLUE}================================================${NC}"
        echo

        if "$DEPLOY_SCRIPT" "$host"; then
            echo -e "${GREEN}✓ $host - SUCCESS${NC}"
            successful_hosts+=("$host")
        else
            echo -e "${RED}✗ $host - FAILED${NC}"
            failed_hosts+=("$host")
        fi

        echo
        echo "Waiting 5 seconds before next host..."
        sleep 5
    done

    echo
    echo "========================================"
    echo "Deployment Summary"
    echo "========================================"
    echo "Total hosts: ${#RPI_HOSTS[@]}"
    echo -e "${GREEN}Successful: ${#successful_hosts[@]}${NC}"
    echo -e "${RED}Failed: ${#failed_hosts[@]}${NC}"

    if [[ ${#successful_hosts[@]} -gt 0 ]]; then
        echo
        echo "Successful hosts:"
        for host in "${successful_hosts[@]}"; do
            echo "  ✓ $host"
        done
    fi

    if [[ ${#failed_hosts[@]} -gt 0 ]]; then
        echo
        echo "Failed hosts:"
        for host in "${failed_hosts[@]}"; do
            echo "  ✗ $host"
        done
        exit 1
    else
        echo
        echo -e "${GREEN}All hosts deployed successfully!${NC}"
    fi
}

main
