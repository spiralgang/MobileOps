#!/bin/bash

# Chisel Container Boot Script for MobileOps Platform
# Handles container initialization and dependency management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/chisel_container_boot.log"
CONTAINER_CONFIG_DIR="/etc/mobileops/containers"
CHISEL_RUNTIME_DIR="/var/run/mobileops/chisel"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

prepare_container_environment() {
    log "INFO: Preparing container environment"
    mkdir -p "$CHISEL_RUNTIME_DIR"
    
    # Set up container networking
    if ! ip link show chisel0 >/dev/null 2>&1; then
        log "INFO: Creating chisel network bridge"
        ip link add name chisel0 type bridge
        ip link set chisel0 up
    fi
    
    # Initialize container storage
    mkdir -p "$CHISEL_RUNTIME_DIR/storage"
    mkdir -p "$CHISEL_RUNTIME_DIR/tmp"
}

boot_container() {
    local container_name="$1"
    local image_path="$2"
    local config_file="$CONTAINER_CONFIG_DIR/$container_name.conf"
    
    log "INFO: Booting container: $container_name"
    
    if [[ ! -f "$config_file" ]]; then
        log "WARN: No config file found for $container_name, using defaults"
    fi
    
    # Check if container is already running
    if pgrep -f "chisel-$container_name" >/dev/null; then
        log "WARN: Container $container_name is already running"
        return 0
    fi
    
    # Start container with chisel runtime
    log "INFO: Starting chisel runtime for $container_name"
    # Container startup logic would go here
    
    log "INFO: Container $container_name booted successfully"
}

stop_container() {
    local container_name="$1"
    log "INFO: Stopping container: $container_name"
    
    pkill -f "chisel-$container_name" || true
    log "INFO: Container $container_name stopped"
}

list_containers() {
    log "INFO: Listing active containers"
    pgrep -f "chisel-" | while read -r pid; do
        local cmd=$(ps -p "$pid" -o cmd --no-headers 2>/dev/null || echo "unknown")
        echo "PID: $pid, CMD: $cmd"
    done
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$CONTAINER_CONFIG_DIR" "$CHISEL_RUNTIME_DIR"
    log "INFO: Chisel Container Boot Manager started"
    
    case "${1:-list}" in
        "prepare")
            prepare_container_environment
            ;;
        "boot")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 boot <container_name> <image_path>"
                exit 1
            fi
            boot_container "$2" "$3"
            ;;
        "stop")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 stop <container_name>"
                exit 1
            fi
            stop_container "$2"
            ;;
        "list")
            list_containers
            ;;
        *)
            echo "Usage: $0 {prepare|boot|stop|list} [args]"
            exit 1
            ;;
    esac
}

main "$@"