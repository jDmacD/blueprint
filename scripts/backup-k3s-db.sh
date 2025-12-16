#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gum rsync
# Script to backup k3s database from tpi01 control plane
# Usage: ./backup-k3s-db.sh [backup-directory]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTROL_PLANE_HOST="tpi01.lan"
CONTROL_PLANE_USER="jmacdonald"
K3S_DB_PATH="/var/lib/rancher/k3s/server/db"
BACKUP_BASE_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/k3s-db-${TIMESTAMP}"

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
    log_info "Checking if ${CONTROL_PLANE_HOST} is reachable..."
    if ping -c 1 -W 2 "${CONTROL_PLANE_HOST}" &>/dev/null; then
        log_info "${CONTROL_PLANE_HOST} is reachable"
        return 0
    else
        log_error "${CONTROL_PLANE_HOST} is not reachable"
        return 1
    fi
}

check_k3s_running() {
    log_info "Checking if k3s is running on ${CONTROL_PLANE_HOST}..."
    if ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "systemctl is-active --quiet k3s" 2>/dev/null; then
        log_info "k3s is running"
        return 0
    else
        log_warn "k3s is not running or cannot be checked"
        return 1
    fi
}

get_db_size() {
    local size
    size=$(ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "sudo du -sh ${K3S_DB_PATH} 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "unknown")
    echo "${size}"
}

create_backup() {
    log_info "Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"

    log_info "Database size: $(get_db_size)"

    log_info "Backing up k3s database from ${CONTROL_PLANE_HOST}:${K3S_DB_PATH}"
    log_info "Destination: ${BACKUP_DIR}"

    # Create a temporary copy on the remote with proper permissions
    local remote_temp="/tmp/k3s-db-backup-$$"
    log_info "Creating temporary copy on remote host..."

    if ! ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "sudo mkdir -p ${remote_temp} && sudo cp -a ${K3S_DB_PATH}/. ${remote_temp}/ && sudo chown -R ${CONTROL_PLANE_USER}:users ${remote_temp}"; then
        log_error "Failed to create temporary copy on remote host"
        return 1
    fi

    # Create backup using rsync for efficient transfer
    if rsync -avz --progress \
        -e "ssh" \
        "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}:${remote_temp}/" \
        "${BACKUP_DIR}/"; then
        # Clean up temporary directory on remote
        ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "sudo rm -rf ${remote_temp}" 2>/dev/null || true
        log_info "Backup completed successfully"
        return 0
    else
        # Clean up temporary directory on remote even on failure
        ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "sudo rm -rf ${remote_temp}" 2>/dev/null || true
        log_error "Backup failed"
        return 1
    fi
}

create_metadata() {
    local metadata_file="${BACKUP_DIR}/backup-metadata.txt"

    log_info "Creating backup metadata..."

    cat > "${metadata_file}" << EOF
K3S Database Backup Metadata
============================

Backup Timestamp: ${TIMESTAMP}
Source Host: ${CONTROL_PLANE_HOST}
Source Path: ${K3S_DB_PATH}
Backup Path: ${BACKUP_DIR}

Host Information:
-----------------
EOF

    # Get k3s version
    local k3s_version
    k3s_version=$(ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "k3s --version 2>/dev/null | head -1" 2>/dev/null || echo "unknown")
    echo "K3s Version: ${k3s_version}" >> "${metadata_file}"

    # Get node information
    local nodes
    nodes=$(ssh "${CONTROL_PLANE_USER}@${CONTROL_PLANE_HOST}" "kubectl get nodes --no-headers 2>/dev/null | wc -l" 2>/dev/null || echo "unknown")
    echo "Number of Nodes: ${nodes}" >> "${metadata_file}"

    # Get database file list
    echo "" >> "${metadata_file}"
    echo "Database Files:" >> "${metadata_file}"
    echo "---------------" >> "${metadata_file}"
    find "${BACKUP_DIR}" -type f -name "*.db*" -o -name "*.wal*" | while read -r file; do
        local rel_path="${file#${BACKUP_DIR}/}"
        local size=$(du -h "${file}" | awk '{print $1}')
        echo "${rel_path} (${size})" >> "${metadata_file}"
    done

    log_info "Metadata saved to ${metadata_file}"
}

create_archive() {
    log_info "Creating compressed archive..."

    local archive_name="${BACKUP_BASE_DIR}/k3s-db-${TIMESTAMP}.tar.gz"

    if tar -czf "${archive_name}" -C "${BACKUP_BASE_DIR}" "k3s-db-${TIMESTAMP}"; then
        log_info "Archive created: ${archive_name}"

        # Get archive size
        local archive_size=$(du -h "${archive_name}" | awk '{print $1}')
        log_info "Archive size: ${archive_size}"

        # Ask if user wants to keep uncompressed backup
        echo ""
        read -p "Remove uncompressed backup directory? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${BACKUP_DIR}"
            log_info "Removed uncompressed backup directory"
        else
            log_info "Kept uncompressed backup at ${BACKUP_DIR}"
        fi

        return 0
    else
        log_error "Failed to create archive"
        return 1
    fi
}

list_recent_backups() {
    echo ""
    echo "Recent backups:"
    echo "==============="

    if [[ -d "${BACKUP_BASE_DIR}" ]]; then
        find "${BACKUP_BASE_DIR}" -maxdepth 1 \( -name "k3s-db-*.tar.gz" -o -type d -name "k3s-db-*" \) | sort -r | head -5 | while read -r backup; do
            local size=$(du -sh "${backup}" 2>/dev/null | awk '{print $1}')
            local name=$(basename "${backup}")
            echo "  ${name} (${size})"
        done
    else
        echo "  No backups found"
    fi
}

main() {
    echo "========================================"
    echo "K3S Database Backup Script"
    echo "========================================"
    echo ""

    log_info "Control Plane: ${CONTROL_PLANE_HOST}"
    log_info "Database Path: ${K3S_DB_PATH}"
    log_info "Backup Directory: ${BACKUP_BASE_DIR}"
    echo ""

    # Pre-flight checks
    if ! check_host_reachable; then
        exit 1
    fi

    check_k3s_running || true

    # Create backup
    if ! create_backup; then
        exit 1
    fi

    # Create metadata
    create_metadata

    # Create archive
    echo ""
    read -p "Create compressed archive? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        create_archive
    fi

    # Show recent backups
    list_recent_backups

    echo ""
    log_info "Backup completed successfully!"
    log_info "Backup location: ${BACKUP_DIR}"
}

main "$@"
