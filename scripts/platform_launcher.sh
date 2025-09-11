#!/bin/bash

# Platform Launcher Script for MobileOps Platform
# Main entry point for initializing and managing the MobileOps platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/platform_launcher.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

initialize_platform() {
    log "INFO: Initializing MobileOps Platform"
    
    # Create necessary directories
    mkdir -p /var/log/mobileops
    mkdir -p /etc/mobileops
    mkdir -p /var/lib/mobileops
    mkdir -p /var/run/mobileops
    
    # Initialize all components
    "$SCRIPT_DIR/component_provisioner.sh" ai-core
    "$SCRIPT_DIR/network_configure.sh" setup-container
    "$SCRIPT_DIR/plugin_manager.sh" init
    "$SCRIPT_DIR/asset_manager.sh" init
    
    log "INFO: MobileOps Platform initialized successfully"
}

start_platform() {
    log "INFO: Starting MobileOps Platform services"
    
    # Start core services
    "$SCRIPT_DIR/ai_core_manager.sh" start
    "$SCRIPT_DIR/system_log_collector.sh" collect
    
    log "INFO: MobileOps Platform services started"
}

stop_platform() {
    log "INFO: Stopping MobileOps Platform services"
    
    # Stop all running components
    pkill -f "mobileops" || true
    
    log "INFO: MobileOps Platform services stopped"
}

status_platform() {
    log "INFO: Checking MobileOps Platform status"
    
    echo "=== MOBILEOPS PLATFORM STATUS ==="
    echo "AI Core Status:"
    "$SCRIPT_DIR/ai_core_manager.sh" status
    
    echo -e "\nNetwork Status:"
    "$SCRIPT_DIR/network_configure.sh" monitor
    
    echo -e "\nPlugin Status:"
    "$SCRIPT_DIR/plugin_manager.sh" monitor
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    log "INFO: Platform Launcher started"
    
    case "${1:-status}" in
        "init")
            initialize_platform
            ;;
        "start")
            start_platform
            ;;
        "stop")
            stop_platform
            ;;
        "restart")
            stop_platform
            sleep 2
            start_platform
            ;;
        "status")
            status_platform
            ;;
        *)
            echo "Usage: $0 {init|start|stop|restart|status}"
            exit 1
            ;;
    esac
}

main "$@"
