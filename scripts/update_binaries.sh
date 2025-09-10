#!/bin/bash

# Update Binaries Script for MobileOps Platform
# Handles secure binary updates and rollback capabilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/update_binaries.log"
UPDATE_CONFIG_DIR="/etc/mobileops/updates"
BINARY_BACKUP_DIR="/var/backups/mobileops"
UPDATE_CACHE_DIR="/var/cache/mobileops/updates"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_update_available() {
    log "INFO: Checking for available updates"
    
    local update_server="${UPDATE_SERVER:-https://updates.mobileops.local}"
    local current_version=$(cat /etc/mobileops/version 2>/dev/null || echo "unknown")
    
    log "INFO: Current version: $current_version"
    
    # Simulate update check
    if curl -sf "$update_server/latest" >/dev/null 2>&1; then
        local latest_version=$(curl -s "$update_server/latest" || echo "unknown")
        log "INFO: Latest version: $latest_version"
        
        if [[ "$current_version" != "$latest_version" ]]; then
            log "INFO: Update available: $current_version -> $latest_version"
            return 0
        else
            log "INFO: System is up to date"
            return 1
        fi
    else
        log "WARN: Cannot reach update server"
        return 1
    fi
}

backup_current_binaries() {
    log "INFO: Backing up current binaries"
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BINARY_BACKUP_DIR/$backup_timestamp"
    
    mkdir -p "$backup_dir"
    
    # Backup MobileOps scripts
    cp -r "$SCRIPT_DIR" "$backup_dir/scripts"
    
    # Backup system components
    if [[ -d "/opt/mobileops" ]]; then
        cp -r "/opt/mobileops" "$backup_dir/components"
    fi
    
    # Backup configuration
    if [[ -d "/etc/mobileops" ]]; then
        cp -r "/etc/mobileops" "$backup_dir/config"
    fi
    
    echo "$backup_timestamp" > "$BINARY_BACKUP_DIR/latest_backup"
    log "INFO: Backup completed: $backup_dir"
}

download_updates() {
    local update_package="$1"
    log "INFO: Downloading update package: $update_package"
    
    mkdir -p "$UPDATE_CACHE_DIR"
    local update_url="${UPDATE_SERVER:-https://updates.mobileops.local}/$update_package"
    local local_file="$UPDATE_CACHE_DIR/$update_package"
    
    if curl -L -o "$local_file" "$update_url"; then
        log "INFO: Downloaded: $local_file"
        
        # Verify checksum if available
        if curl -sf "${update_url}.sha256" >/dev/null; then
            local expected_hash=$(curl -s "${update_url}.sha256")
            local actual_hash=$(sha256sum "$local_file" | cut -d' ' -f1)
            
            if [[ "$expected_hash" == "$actual_hash" ]]; then
                log "INFO: Checksum verification passed"
            else
                log "ERROR: Checksum verification failed"
                rm -f "$local_file"
                return 1
            fi
        fi
        
        return 0
    else
        log "ERROR: Failed to download update package"
        return 1
    fi
}

apply_updates() {
    local update_package="$1"
    local local_file="$UPDATE_CACHE_DIR/$update_package"
    
    log "INFO: Applying updates from: $update_package"
    
    if [[ ! -f "$local_file" ]]; then
        log "ERROR: Update package not found: $local_file"
        return 1
    fi
    
    # Create temporary extraction directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Extract update package
    if tar -xzf "$local_file" -C "$temp_dir"; then
        log "INFO: Extracted update package"
    else
        log "ERROR: Failed to extract update package"
        return 1
    fi
    
    # Apply script updates
    if [[ -d "$temp_dir/scripts" ]]; then
        log "INFO: Updating scripts"
        cp -r "$temp_dir/scripts/"* "$SCRIPT_DIR/"
        chmod +x "$SCRIPT_DIR"/*.sh
    fi
    
    # Apply component updates
    if [[ -d "$temp_dir/components" ]]; then
        log "INFO: Updating components"
        mkdir -p "/opt/mobileops"
        cp -r "$temp_dir/components/"* "/opt/mobileops/"
    fi
    
    # Apply configuration updates
    if [[ -d "$temp_dir/config" ]]; then
        log "INFO: Updating configuration"
        cp -r "$temp_dir/config/"* "/etc/mobileops/"
    fi
    
    # Update version file
    if [[ -f "$temp_dir/version" ]]; then
        cp "$temp_dir/version" "/etc/mobileops/version"
        local new_version=$(cat "/etc/mobileops/version")
        log "INFO: Updated to version: $new_version"
    fi
    
    log "INFO: Updates applied successfully"
}

rollback_updates() {
    log "INFO: Rolling back to previous version"
    
    if [[ ! -f "$BINARY_BACKUP_DIR/latest_backup" ]]; then
        log "ERROR: No backup available for rollback"
        return 1
    fi
    
    local backup_timestamp=$(cat "$BINARY_BACKUP_DIR/latest_backup")
    local backup_dir="$BINARY_BACKUP_DIR/$backup_timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        log "ERROR: Backup directory not found: $backup_dir"
        return 1
    fi
    
    log "INFO: Restoring from backup: $backup_timestamp"
    
    # Restore scripts
    if [[ -d "$backup_dir/scripts" ]]; then
        rm -rf "$SCRIPT_DIR"/*
        cp -r "$backup_dir/scripts/"* "$SCRIPT_DIR/"
        chmod +x "$SCRIPT_DIR"/*.sh
    fi
    
    # Restore components
    if [[ -d "$backup_dir/components" ]]; then
        rm -rf "/opt/mobileops"
        cp -r "$backup_dir/components" "/opt/mobileops"
    fi
    
    # Restore configuration
    if [[ -d "$backup_dir/config" ]]; then
        rm -rf "/etc/mobileops"
        cp -r "$backup_dir/config" "/etc/mobileops"
    fi
    
    log "INFO: Rollback completed successfully"
}

list_backups() {
    log "INFO: Available backups:"
    
    if [[ -d "$BINARY_BACKUP_DIR" ]]; then
        ls -1 "$BINARY_BACKUP_DIR" | grep -E "^[0-9]{8}_[0-9]{6}$" | sort -r | head -10
    else
        log "INFO: No backups found"
    fi
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$UPDATE_CONFIG_DIR" "$BINARY_BACKUP_DIR" "$UPDATE_CACHE_DIR"
    log "INFO: Binary Update Manager started"
    
    case "${1:-check}" in
        "check")
            check_update_available
            ;;
        "download")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 download <update_package>"
                exit 1
            fi
            download_updates "$2"
            ;;
        "update")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 update <update_package>"
                exit 1
            fi
            backup_current_binaries
            if download_updates "$2"; then
                apply_updates "$2"
            else
                log "ERROR: Update failed during download"
                exit 1
            fi
            ;;
        "rollback")
            rollback_updates
            ;;
        "backup")
            backup_current_binaries
            ;;
        "list-backups")
            list_backups
            ;;
        *)
            echo "Usage: $0 {check|download|update|rollback|backup|list-backups} [args]"
            exit 1
            ;;
    esac
}

main "$@"