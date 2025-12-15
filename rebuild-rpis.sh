#!/usr/bin/env bash
# Script to rebuild all Raspberry Pi hosts in the cluster
# Usage: ./rebuild-rpis.sh [--dry-run]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
USER="jmacdonald"
DOMAIN=".lan"
DRY_RUN=false

# Parse arguments
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}\n"
fi

# Define all Raspberry Pi hosts
# Format: "hostname:description"
declare -a RPI_HOSTS=(
    "pi01:Raspberry Pi 4B - k3s agent"
    "pi02:Raspberry Pi 4B - k3s agent"
    "pi03:Raspberry Pi 4B - k3s agent"
    "pi04:Raspberry Pi 5 - k3s agent"
    "pi05:Raspberry Pi 5 - k3s agent"
    # "tpi01:Compute Module 4 - k3s control plane"
    # "tpi02:Compute Module 4 - k3s agent"
    # "tpi03:Compute Module 4 - k3s agent"
    "tpi04:Compute Module 4 - k3s agent"
)

# Track results
declare -a SUCCEEDED=()
declare -a FAILED=()

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_host_reachable() {
    local host=$1
    if ping -c 1 -W 2 "${host}${DOMAIN}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

rebuild_host() {
    local hostname=$1
    local description=$2
    local target="${USER}@${hostname}${DOMAIN}"

    echo ""
    echo "========================================"
    log_info "Host: ${hostname} (${description})"
    echo "========================================"

    # Check if host is reachable
    log_info "Checking if ${hostname} is reachable..."
    if ! check_host_reachable "${hostname}"; then
        log_error "${hostname} is not reachable"
        FAILED+=("${hostname} (unreachable)")
        return 1
    fi

    log_info "${hostname} is reachable"

    # Check boot partition space
    log_info "Checking boot partition space..."
    local boot_usage
    boot_usage=$(ssh "${target}" "df -h /boot/firmware | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "unknown")

    if [[ "${boot_usage}" != "unknown" ]]; then
        log_info "Boot partition usage: ${boot_usage}%"
        if [[ ${boot_usage} -gt 80 ]]; then
            log_warn "Boot partition is >80% full, cleaning up..."
            if [[ "${DRY_RUN}" == false ]]; then
                ssh "${target}" "sudo rm -rf /boot/firmware/nixos/*.tmp.* /boot/firmware/nixos/*-default" || true
                ssh "${target}" "sudo nix-collect-garbage -d" || true
                boot_usage=$(ssh "${target}" "df -h /boot/firmware | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "unknown")
                log_info "Boot partition usage after cleanup: ${boot_usage}%"
            fi
        fi
    fi

    # Perform rebuild
    if [[ "${DRY_RUN}" == true ]]; then
        log_info "DRY RUN: Would run: nixos-rebuild --use-remote-sudo --target-host ${target} --flake .#${hostname} switch"
        SUCCEEDED+=("${hostname} (dry-run)")
        return 0
    fi

    log_info "Starting rebuild for ${hostname}..."
    if nixos-rebuild --use-remote-sudo --target-host "${target}" --flake ".#${hostname}" switch; then
        log_info "Successfully rebuilt ${hostname}"
        SUCCEEDED+=("${hostname}")
        return 0
    else
        log_error "Failed to rebuild ${hostname}"
        FAILED+=("${hostname}")
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting rebuild of ${#RPI_HOSTS[@]} Raspberry Pi hosts"
    log_info "User: ${USER}"
    log_info "Domain: ${DOMAIN}"
    echo ""

    for host_entry in "${RPI_HOSTS[@]}"; do
        IFS=':' read -r hostname description <<< "${host_entry}"
        rebuild_host "${hostname}" "${description}" || true
    done

    # Print summary
    echo ""
    echo "========================================"
    echo "SUMMARY"
    echo "========================================"

    if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
        echo -e "${GREEN}Succeeded (${#SUCCEEDED[@]}):${NC}"
        for host in "${SUCCEEDED[@]}"; do
            echo "  ✓ ${host}"
        done
    fi

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed (${#FAILED[@]}):${NC}"
        for host in "${FAILED[@]}"; do
            echo "  ✗ ${host}"
        done
    fi

    echo ""
    log_info "Total: ${#RPI_HOSTS[@]} hosts, ${#SUCCEEDED[@]} succeeded, ${#FAILED[@]} failed"

    # Exit with error if any failed
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
