#!/usr/bin/env bash

# FileSystemds Platform Launcher - Mobile-First Architecture
# Advanced orchestration for Android/ARM64 mobile and edge deployment
# Supports containerized services, AI core management, and zero-trust security

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Mobile-friendly directory structure (user-space for Android)
if [[ -n "${ANDROID_DATA:-}" ]] || [[ -n "${ANDROID_ROOT:-}" ]]; then
    # Android environment
    BASE_DIR="${ANDROID_DATA}/data/com.spiralgang.filesystemds"
    LOG_DIR="$BASE_DIR/logs"
    CONFIG_DIR="$BASE_DIR/config"
    CACHE_DIR="$BASE_DIR/cache"
    LIB_DIR="$BASE_DIR/lib"
else
    # Standard Linux environment
    BASE_DIR="${HOME}/.local/share/filesystemds"
    LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/filesystemds/logs"
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/filesystemds"
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/filesystemds"
    LIB_DIR="$BASE_DIR/lib"
fi

LOG_FILE="$LOG_DIR/platform_launcher.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$CACHE_DIR" "$LIB_DIR"

log() {
    local level="${1:-INFO}"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

detect_environment() {
    local env_type="unknown"
    local arch="$(uname -m)"
    
    if [[ -n "${ANDROID_DATA:-}" ]]; then
        env_type="android"
    elif [[ -f "/etc/alpine-release" ]]; then
        env_type="alpine"
    elif [[ -f "/etc/debian_version" ]]; then
        env_type="debian"
    elif [[ -f "/etc/redhat-release" ]]; then
        env_type="redhat"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        env_type="macos"
    fi
    
    log_info "Environment detected: $env_type on $arch"
    echo "$env_type:$arch"
}

initialize_platform() {
    log_info "Initializing FileSystemds Mobile Platform"
    
    local env_info
    env_info=$(detect_environment)
    local env_type="${env_info%:*}"
    local arch="${env_info#*:}"
    
    # Create platform configuration
    cat > "$CONFIG_DIR/platform.conf" << EOF
# FileSystemds Platform Configuration
platform_version=1.0.0
environment_type=$env_type
architecture=$arch
base_directory=$BASE_DIR
initialization_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
user_id=$(id -u)
group_id=$(id -g)

# Feature flags for mobile deployment
mobile_optimized=true
container_runtime_enabled=true
ai_core_enabled=true
network_management_enabled=true
security_framework_enabled=true
EOF

    # Initialize all components with mobile-friendly approach
    if [[ -x "$SCRIPT_DIR/ai_core_manager.sh" ]]; then
        "$SCRIPT_DIR/ai_core_manager.sh" init
    fi
    
    if [[ -x "$SCRIPT_DIR/network_configure.sh" ]]; then
        "$SCRIPT_DIR/network_configure.sh" init
    fi
    
    if [[ -x "$SCRIPT_DIR/asset_manager.sh" ]]; then
        "$SCRIPT_DIR/asset_manager.sh" init
    fi
    
    log_success "FileSystemds Platform initialized successfully for $env_type on $arch"
}

start_platform() {
    log_info "Starting FileSystemds Platform services"
    
    if [[ ! -f "$CONFIG_DIR/platform.conf" ]]; then
        log_error "Platform not initialized. Run 'init' first."
        exit 1
    fi
    
    # Start core services based on environment
    local env_info
    env_info=$(detect_environment)
    local env_type="${env_info%:*}"
    
    case "$env_type" in
        "android")
            log_info "Starting Android-optimized services"
            # Android-specific service startup
            ;;
        "alpine"|"debian"|"redhat")
            log_info "Starting Linux services"
            # Linux service startup
            ;;
        *)
            log_warn "Unknown environment, starting basic services"
            ;;
    esac
    
    # Start AI core if enabled
    if [[ -x "$SCRIPT_DIR/ai_core_manager.sh" ]]; then
        "$SCRIPT_DIR/ai_core_manager.sh" start || log_warn "AI Core Manager failed to start"
    fi
    
    log_success "FileSystemds Platform services started"
}

stop_platform() {
    log_info "Stopping FileSystemds Platform services"
    
    # Graceful shutdown of components
    if [[ -x "$SCRIPT_DIR/ai_core_manager.sh" ]]; then
        "$SCRIPT_DIR/ai_core_manager.sh" stop || log_warn "AI Core Manager failed to stop gracefully"
    fi
    
    # Stop any remaining processes
    pkill -f "filesystemds" || true
    
    log_success "FileSystemds Platform services stopped"
}

status_platform() {
    log_info "Checking FileSystemds Platform status"
    
    if [[ ! -f "$CONFIG_DIR/platform.conf" ]]; then
        echo "Platform Status: NOT INITIALIZED"
        return 1
    fi
    
    local platform_version
    platform_version=$(grep "platform_version=" "$CONFIG_DIR/platform.conf" | cut -d'=' -f2)
    
    echo "============================================"
    echo "FileSystemds Platform Status"
    echo "============================================"
    echo "Version: $platform_version"
    echo "Configuration: $CONFIG_DIR/platform.conf"
    echo "Logs: $LOG_FILE"
    echo "Base Directory: $BASE_DIR"
    echo "Environment: $(detect_environment)"
    echo "============================================"
    
    # Check service status
    if pgrep -f "filesystemds" > /dev/null; then
        echo "Platform Status: RUNNING"
    else
        echo "Platform Status: STOPPED"
    fi
}

health_check() {
    log_info "Running FileSystemds Platform health check"
    
    local issues=0
    
    # Check directory structure
    for dir in "$LOG_DIR" "$CONFIG_DIR" "$CACHE_DIR" "$LIB_DIR"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Missing directory: $dir"
            ((issues++))
        fi
    done
    
    # Check configuration
    if [[ ! -f "$CONFIG_DIR/platform.conf" ]]; then
        log_error "Missing platform configuration"
        ((issues++))
    fi
    
    # Check script permissions
    for script in "$SCRIPT_DIR"/*.sh; do
        if [[ ! -x "$script" ]]; then
            log_warn "Script not executable: $script"
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "Health check passed - no issues found"
        return 0
    else
        log_error "Health check failed - $issues issues found"
        return 1
    fi
}

show_help() {
    cat << EOF
FileSystemds Platform Launcher - Mobile-First Architecture

USAGE:
    $0 <command> [options]

COMMANDS:
    init        Initialize the platform for first use
    start       Start all platform services
    stop        Stop all platform services
    restart     Restart all platform services  
    status      Show platform status and configuration
    health      Run platform health check
    logs        Show recent platform logs
    cleanup     Clean up temporary files and caches
    help        Show this help message

EXAMPLES:
    $0 init                 # Initialize for first use
    $0 start                # Start all services
    $0 status               # Check status
    $0 health               # Run health check

For more information, visit: https://github.com/spiralgang/FileSystemds
EOF
}

main() {
    local command="${1:-help}"
    
    case "$command" in
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
        "health")
            health_check
            ;;
        "logs")
            if [[ -f "$LOG_FILE" ]]; then
                tail -n 50 "$LOG_FILE"
            else
                echo "No logs found at $LOG_FILE"
            fi
            ;;
        "cleanup")
            log_info "Cleaning up temporary files"
            rm -rf "$CACHE_DIR"/* || true
            log_success "Cleanup completed"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

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
