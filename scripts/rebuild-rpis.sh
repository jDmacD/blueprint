#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gum
# Script to rebuild all Raspberry Pi hosts in the cluster
# Usage: ./rebuild-rpis.sh [--dry-run] [--all] [--no-select]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USER="jmacdonald"
DOMAIN=".lan"
DRY_RUN=false
SELECT_HOSTS=true
ALL_HOSTS=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --all)
            ALL_HOSTS=true
            SELECT_HOSTS=false
            ;;
        --no-select)
            SELECT_HOSTS=false
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--dry-run] [--all] [--no-select]"
            exit 1
            ;;
    esac
done

if [[ "${DRY_RUN}" == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}\n"
fi

# Define all Raspberry Pi hosts
# Format: "hostname:description"
declare -a ALL_RPI_HOSTS=(
    "pi01:Raspberry Pi 4B - k3s agent"
    "pi02:Raspberry Pi 4B - k3s agent"
    "pi03:Raspberry Pi 4B - k3s agent"
    "pi04:Raspberry Pi 5 - k3s agent"
    "pi05:Raspberry Pi 5 - k3s agent"
    "tpi01:Compute Module 4 - k3s control plane"
    "tpi02:Compute Module 4 - k3s agent"
    "tpi03:Compute Module 4 - k3s agent"
    "tpi04:Compute Module 4 - k3s agent"
)

declare -a RPI_HOSTS=()

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
        if [[ ${boot_usage} -gt 50 ]]; then
            log_warn "Boot partition is >50% full, cleaning up..."
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

# Select hosts using gum
select_hosts() {
    # Check if gum is installed
    if ! command -v gum &> /dev/null; then
        log_error "gum is not installed. Please install it: https://github.com/charmbracelet/gum"
        exit 1
    fi

    echo -e "${BLUE}Select hosts to rebuild (Space to select, Enter to confirm):${NC}"
    echo ""

    # Create options for gum
    local options=()
    for host_entry in "${ALL_RPI_HOSTS[@]}"; do
        IFS=':' read -r hostname description <<< "${host_entry}"
        options+=("${hostname} (${description})")
    done

    # Use gum to select hosts
    local selected
    selected=$(printf '%s\n' "${options[@]}" | gum choose --no-limit --header "Select hosts to rebuild:")

    if [[ -z "${selected}" ]]; then
        log_error "No hosts selected"
        exit 1
    fi

    # Parse selected hosts back into RPI_HOSTS array
    while IFS= read -r line; do
        # Extract hostname from "hostname (description)" format
        local hostname
        hostname=$(echo "${line}" | sed 's/ (.*//')

        # Find matching entry in ALL_RPI_HOSTS
        for host_entry in "${ALL_RPI_HOSTS[@]}"; do
            if [[ "${host_entry}" == "${hostname}:"* ]]; then
                RPI_HOSTS+=("${host_entry}")
                break
            fi
        done
    done <<< "${selected}"

    echo ""
    log_info "Selected ${#RPI_HOSTS[@]} host(s) for rebuild"
}

# Main execution
main() {
    # Determine which hosts to rebuild
    if [[ "${ALL_HOSTS}" == true ]]; then
        RPI_HOSTS=("${ALL_RPI_HOSTS[@]}")
        log_info "Rebuilding ALL ${#RPI_HOSTS[@]} Raspberry Pi hosts"
    elif [[ "${SELECT_HOSTS}" == true ]]; then
        select_hosts
    else
        # Default to all if --no-select is passed
        RPI_HOSTS=("${ALL_RPI_HOSTS[@]}")
        log_info "Rebuilding ${#RPI_HOSTS[@]} Raspberry Pi hosts (no selection)"
    fi

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
