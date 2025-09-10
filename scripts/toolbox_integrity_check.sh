#!/bin/bash

# Toolbox Integrity Check Script for MobileOps Platform
# Performs comprehensive system integrity verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/toolbox_integrity.log"
INTEGRITY_CONFIG_DIR="/etc/mobileops/integrity"
CHECKSUM_FILE="$INTEGRITY_CONFIG_DIR/checksums.sha256"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_system_binaries() {
    log "INFO: Checking system binary integrity"
    
    local critical_binaries=(
        "/bin/bash"
        "/bin/sh"
        "/usr/bin/sudo"
        "/usr/bin/ssh"
        "/usr/bin/systemctl"
    )
    
    for binary in "${critical_binaries[@]}"; do
        if [[ -f "$binary" ]]; then
            local checksum=$(sha256sum "$binary" | cut -d' ' -f1)
            log "INFO: $binary - $checksum"
        else
            log "ERROR: Critical binary missing: $binary"
        fi
    done
}

verify_mobileops_components() {
    log "INFO: Verifying MobileOps component integrity"
    
    local components_dir="/opt/mobileops"
    local scripts_dir="$SCRIPT_DIR"
    
    # Check script integrity
    for script in "$scripts_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            local checksum=$(sha256sum "$script" | cut -d' ' -f1)
            log "INFO: Script $(basename "$script") - $checksum"
        fi
    done
    
    # Check component binaries if they exist
    if [[ -d "$components_dir" ]]; then
        find "$components_dir" -type f -executable | while read -r file; do
            local checksum=$(sha256sum "$file" | cut -d' ' -f1)
            log "INFO: Component $file - $checksum"
        done
    fi
}

check_configuration_files() {
    log "INFO: Checking configuration file integrity"
    
    local config_dirs=(
        "/etc/mobileops"
        "/etc/systemd/system"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            find "$config_dir" -type f -name "*.conf" -o -name "*.service" | while read -r file; do
                local checksum=$(sha256sum "$file" | cut -d' ' -f1)
                log "INFO: Config $file - $checksum"
            done
        fi
    done
}

verify_network_security() {
    log "INFO: Checking network security configuration"
    
    # Check firewall rules
    if command -v iptables >/dev/null; then
        local rules_count=$(iptables -L | wc -l)
        log "INFO: Firewall rules count: $rules_count"
    fi
    
    # Check open ports
    if command -v ss >/dev/null; then
        local listening_ports=$(ss -tuln | grep LISTEN | wc -l)
        log "INFO: Listening ports count: $listening_ports"
    fi
    
    # Check for suspicious network connections
    if command -v netstat >/dev/null; then
        local active_connections=$(netstat -an | grep ESTABLISHED | wc -l)
        log "INFO: Active connections count: $active_connections"
    fi
}

check_container_integrity() {
    log "INFO: Checking container integrity"
    
    # Check container runtime
    if command -v docker >/dev/null; then
        local running_containers=$(docker ps -q | wc -l)
        log "INFO: Running Docker containers: $running_containers"
    fi
    
    # Check for unauthorized containers
    if [[ -d "/var/run/mobileops/chisel" ]]; then
        local chisel_containers=$(find /var/run/mobileops/chisel -name "*.pid" | wc -l)
        log "INFO: Running Chisel containers: $chisel_containers"
    fi
}

generate_baseline() {
    log "INFO: Generating integrity baseline"
    mkdir -p "$INTEGRITY_CONFIG_DIR"
    
    # Generate checksums for critical files
    {
        check_system_binaries 2>/dev/null | grep "INFO:" | cut -d' ' -f3-
        find "$SCRIPT_DIR" -name "*.sh" -exec sha256sum {} \;
        find /etc/mobileops -type f 2>/dev/null -exec sha256sum {} \; || true
    } > "$CHECKSUM_FILE"
    
    log "INFO: Baseline saved to $CHECKSUM_FILE"
}

verify_against_baseline() {
    log "INFO: Verifying against baseline"
    
    if [[ ! -f "$CHECKSUM_FILE" ]]; then
        log "ERROR: No baseline found. Run with 'baseline' first."
        return 1
    fi
    
    local violations=0
    while IFS=' ' read -r expected_hash file; do
        if [[ -f "$file" ]]; then
            local current_hash=$(sha256sum "$file" | cut -d' ' -f1)
            if [[ "$current_hash" != "$expected_hash" ]]; then
                log "VIOLATION: $file - Expected: $expected_hash, Current: $current_hash"
                ((violations++))
            fi
        else
            log "VIOLATION: Missing file: $file"
            ((violations++))
        fi
    done < "$CHECKSUM_FILE"
    
    if [[ $violations -eq 0 ]]; then
        log "INFO: All integrity checks passed"
    else
        log "ERROR: $violations integrity violations found"
        return 1
    fi
}

full_system_check() {
    log "INFO: Starting full system integrity check"
    
    check_system_binaries
    verify_mobileops_components
    check_configuration_files
    verify_network_security
    check_container_integrity
    
    log "INFO: Full system integrity check completed"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$INTEGRITY_CONFIG_DIR"
    log "INFO: Toolbox Integrity Check started"
    
    case "${1:-check}" in
        "check")
            full_system_check
            ;;
        "baseline")
            generate_baseline
            ;;
        "verify")
            verify_against_baseline
            ;;
        "binaries")
            check_system_binaries
            ;;
        "network")
            verify_network_security
            ;;
        "containers")
            check_container_integrity
            ;;
        *)
            echo "Usage: $0 {check|baseline|verify|binaries|network|containers}"
            exit 1
            ;;
    esac
}

main "$@"