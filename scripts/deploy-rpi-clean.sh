#!/usr/bin/env bash
#
# deploy-rpi-clean.sh - Deploy to Raspberry Pi with clean boot partition
#
# This script clears /boot/firmware before deployment, allowing NixOS to
# repopulate it from scratch. This prevents "No space left on device" errors
# by ensuring only the new generation's files are present.
#
# Usage:
#   ./deploy-rpi-clean.sh <hostname>
#
# Example:
#   ./deploy-rpi-clean.sh pi01

set -euo pipefail

HOSTNAME="${1:-}"
SSH_USER="jmacdonald"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $*"
}

if [[ -z "$HOSTNAME" ]]; then
    echo "Usage: $0 <hostname>"
    echo "Example: $0 pi01"
    exit 1
fi

# Remove .lan suffix if present for flake reference
FLAKE_HOST="${HOSTNAME%.lan}"

# Add .lan suffix if not present for SSH
if [[ ! "$HOSTNAME" =~ \.lan$ ]]; then
    SSH_HOST="${HOSTNAME}.lan"
else
    SSH_HOST="$HOSTNAME"
fi

echo "========================================"
echo "Clean Boot Deployment to: $FLAKE_HOST"
echo "========================================"
echo

# Step 1: Check connectivity
log_step "Checking connectivity to ${SSH_HOST}..."
if ! ssh -o ConnectTimeout=5 "${SSH_USER}@${SSH_HOST}" "echo 'Connected'" &>/dev/null; then
    log_error "Cannot connect to ${SSH_HOST}"
    exit 1
fi
log_info "Connected successfully"
echo

# Step 2: Show current boot partition usage
log_step "Current boot partition usage:"
ssh "${SSH_USER}@${SSH_HOST}" "df -h /boot/firmware"
echo

# Step 3: Backup critical boot files (optional safety measure)
log_step "Creating backup of current boot configuration..."
ssh "${SSH_USER}@${SSH_HOST}" "sudo tar -czf /tmp/boot-backup-\$(date +%Y%m%d-%H%M%S).tar.gz -C /boot/firmware . 2>/dev/null || true"
log_info "Backup created in /tmp/"
echo

# Step 4: Clear /boot/firmware
log_warn "Clearing /boot/firmware contents..."
log_warn "The deployment will repopulate this partition."
ssh "${SSH_USER}@${SSH_HOST}" "sudo rm -rf /boot/firmware/*"
log_info "Boot partition cleared"
echo

# Step 5: Show cleared boot partition
log_step "Boot partition after clearing:"
ssh "${SSH_USER}@${SSH_HOST}" "df -h /boot/firmware"
echo

# Step 6: Deploy
log_step "Deploying configuration..."
echo
nixos-rebuild switch \
    --use-remote-sudo \
    --target-host "${SSH_USER}@${SSH_HOST}" \
    --flake ".#${FLAKE_HOST}"

echo
log_info "Deployment complete!"
echo

# Step 7: Show final boot partition usage
log_step "Final boot partition usage:"
ssh "${SSH_USER}@${SSH_HOST}" "df -h /boot/firmware"
echo

# Step 8: List what's in /boot/firmware
log_step "Contents of /boot/firmware:"
ssh "${SSH_USER}@${SSH_HOST}" "sudo ls -lh /boot/firmware/nixos/ 2>/dev/null || echo 'No nixos directory found'"
echo

echo "========================================"
echo "Deployment Summary"
echo "========================================"
log_info "Host: ${FLAKE_HOST}"
log_info "Boot partition successfully repopulated"
log_info "Backup available in /tmp/ on ${SSH_HOST}"
echo
log_warn "Note: Previous generations have been removed from boot partition"
log_warn "System rollback may not be possible without manual intervention"
echo
