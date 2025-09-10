#!/bin/bash

# Plugin Manager for MobileOps Platform
# Handles dynamic loading, management, and lifecycle of platform plugins

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/plugin_manager.log"
PLUGIN_CONFIG_DIR="/etc/mobileops/plugins"
PLUGIN_STORE_DIR="/var/lib/mobileops/plugins"
PLUGIN_RUNTIME_DIR="/var/run/mobileops/plugins"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

initialize_plugin_system() {
    log "INFO: Initializing plugin system"
    
    mkdir -p "$PLUGIN_CONFIG_DIR" "$PLUGIN_STORE_DIR" "$PLUGIN_RUNTIME_DIR"
    
    # Create plugin registry
    local registry_file="$PLUGIN_CONFIG_DIR/registry.json"
    if [[ ! -f "$registry_file" ]]; then
        cat > "$registry_file" <<EOF
{
    "version": "1.0",
    "plugins": {},
    "repositories": [
        "https://plugins.mobileops.local/registry"
    ]
}
EOF
        log "INFO: Plugin registry initialized"
    fi
    
    log "INFO: Plugin system initialized"
}

list_plugins() {
    log "INFO: Listing plugins"
    
    echo "=== INSTALLED PLUGINS ==="
    if [[ -d "$PLUGIN_STORE_DIR" ]]; then
        find "$PLUGIN_STORE_DIR" -maxdepth 1 -type d | while read -r plugin_dir; do
            local plugin_name=$(basename "$plugin_dir")
            if [[ "$plugin_name" != "plugins" && -f "$plugin_dir/plugin.json" ]]; then
                local version=$(grep '"version"' "$plugin_dir/plugin.json" | cut -d'"' -f4 2>/dev/null || echo "unknown")
                local status="inactive"
                if [[ -f "$PLUGIN_RUNTIME_DIR/$plugin_name.pid" ]]; then
                    status="active"
                fi
                echo "$plugin_name ($version) - $status"
            fi
        done
    fi
    
    echo -e "\n=== AVAILABLE PLUGINS ==="
    if command -v curl >/dev/null; then
        # Fetch available plugins from repository
        echo "Fetching from plugin repository..."
        # Simulated plugin list
        echo "ai-vision-plugin (2.1.0) - Computer vision enhancement"
        echo "mobile-sync-plugin (1.5.2) - Mobile device synchronization"
        echo "network-monitor-plugin (3.0.1) - Advanced network monitoring"
        echo "security-scanner-plugin (2.3.0) - Security vulnerability scanning"
    else
        echo "curl not available - cannot fetch remote plugins"
    fi
}

install_plugin() {
    local plugin_name="$1"
    local plugin_version="${2:-latest}"
    
    log "INFO: Installing plugin: $plugin_name ($plugin_version)"
    
    local plugin_dir="$PLUGIN_STORE_DIR/$plugin_name"
    mkdir -p "$plugin_dir"
    
    # Simulate plugin download and installation
    local plugin_url="https://plugins.mobileops.local/$plugin_name-$plugin_version.tar.gz"
    
    if command -v curl >/dev/null; then
        log "INFO: Downloading plugin from: $plugin_url"
        # Simulate download
        log "INFO: Download completed (simulated)"
    fi
    
    # Create plugin metadata
    cat > "$plugin_dir/plugin.json" <<EOF
{
    "name": "$plugin_name",
    "version": "$plugin_version",
    "description": "MobileOps plugin: $plugin_name",
    "author": "MobileOps Team",
    "dependencies": [],
    "entry_point": "main.py",
    "permissions": ["network", "filesystem"],
    "installed_at": "$(date -Iseconds)"
}
EOF
    
    # Create plugin executable
    cat > "$plugin_dir/main.py" <<EOF
#!/usr/bin/env python3
import sys
import time
import json

def main():
    print(f"Plugin $plugin_name started")
    
    # Plugin main loop
    while True:
        try:
            # Plugin logic here
            time.sleep(10)
        except KeyboardInterrupt:
            print(f"Plugin $plugin_name stopping")
            break

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$plugin_dir/main.py"
    
    # Update plugin registry
    update_plugin_registry "$plugin_name" "installed"
    
    log "INFO: Plugin $plugin_name installed successfully"
}

uninstall_plugin() {
    local plugin_name="$1"
    
    log "INFO: Uninstalling plugin: $plugin_name"
    
    # Stop plugin if running
    stop_plugin "$plugin_name"
    
    # Remove plugin directory
    local plugin_dir="$PLUGIN_STORE_DIR/$plugin_name"
    if [[ -d "$plugin_dir" ]]; then
        rm -rf "$plugin_dir"
        log "INFO: Plugin files removed"
    fi
    
    # Update plugin registry
    update_plugin_registry "$plugin_name" "uninstalled"
    
    log "INFO: Plugin $plugin_name uninstalled successfully"
}

start_plugin() {
    local plugin_name="$1"
    local plugin_dir="$PLUGIN_STORE_DIR/$plugin_name"
    local pid_file="$PLUGIN_RUNTIME_DIR/$plugin_name.pid"
    
    log "INFO: Starting plugin: $plugin_name"
    
    if [[ ! -d "$plugin_dir" ]]; then
        log "ERROR: Plugin not found: $plugin_name"
        return 1
    fi
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log "WARN: Plugin $plugin_name is already running (PID: $pid)"
            return 0
        else
            rm -f "$pid_file"
        fi
    fi
    
    # Start plugin
    local entry_point=$(grep '"entry_point"' "$plugin_dir/plugin.json" | cut -d'"' -f4 2>/dev/null || echo "main.py")
    
    cd "$plugin_dir"
    nohup "./$entry_point" > "$PLUGIN_RUNTIME_DIR/$plugin_name.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$pid_file"
    
    log "INFO: Plugin $plugin_name started (PID: $pid)"
    
    # Update plugin registry
    update_plugin_registry "$plugin_name" "active"
}

stop_plugin() {
    local plugin_name="$1"
    local pid_file="$PLUGIN_RUNTIME_DIR/$plugin_name.pid"
    
    log "INFO: Stopping plugin: $plugin_name"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -TERM "$pid" 2>/dev/null; then
            log "INFO: Sent SIGTERM to plugin $plugin_name (PID: $pid)"
            sleep 3
            if kill -0 "$pid" 2>/dev/null; then
                log "WARN: Plugin didn't stop gracefully, forcing shutdown"
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$pid_file"
    else
        log "WARN: Plugin $plugin_name is not running"
    fi
    
    # Update plugin registry
    update_plugin_registry "$plugin_name" "inactive"
    
    log "INFO: Plugin $plugin_name stopped"
}

update_plugin_registry() {
    local plugin_name="$1"
    local status="$2"
    local registry_file="$PLUGIN_CONFIG_DIR/registry.json"
    
    # Simple registry update (in production, use proper JSON manipulation)
    log "INFO: Updating plugin registry: $plugin_name -> $status"
}

check_plugin_health() {
    local plugin_name="$1"
    local pid_file="$PLUGIN_RUNTIME_DIR/$plugin_name.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Plugin $plugin_name is running (PID: $pid)"
            
            # Check plugin log for recent activity
            local log_file="$PLUGIN_RUNTIME_DIR/$plugin_name.log"
            if [[ -f "$log_file" ]]; then
                local last_activity=$(stat -c %Y "$log_file" 2>/dev/null || echo "0")
                local current_time=$(date +%s)
                local inactive_time=$((current_time - last_activity))
                
                if [[ $inactive_time -gt 300 ]]; then  # 5 minutes
                    echo "WARNING: Plugin appears inactive (no log activity for ${inactive_time}s)"
                else
                    echo "Plugin is healthy"
                fi
            fi
        else
            echo "Plugin $plugin_name is not running"
            rm -f "$pid_file"
        fi
    else
        echo "Plugin $plugin_name is not running"
    fi
}

monitor_plugins() {
    log "INFO: Monitoring all plugins"
    
    echo "=== PLUGIN HEALTH MONITOR ==="
    
    find "$PLUGIN_STORE_DIR" -maxdepth 1 -type d | while read -r plugin_dir; do
        local plugin_name=$(basename "$plugin_dir")
        if [[ "$plugin_name" != "plugins" && -f "$plugin_dir/plugin.json" ]]; then
            check_plugin_health "$plugin_name"
            echo ""
        fi
    done
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$PLUGIN_CONFIG_DIR" "$PLUGIN_STORE_DIR" "$PLUGIN_RUNTIME_DIR"
    log "INFO: Plugin Manager started"
    
    case "${1:-list}" in
        "init")
            initialize_plugin_system
            ;;
        "list")
            list_plugins
            ;;
        "install")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 install <plugin_name> [version]"
                exit 1
            fi
            install_plugin "$2" "${3:-latest}"
            ;;
        "uninstall")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 uninstall <plugin_name>"
                exit 1
            fi
            uninstall_plugin "$2"
            ;;
        "start")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 start <plugin_name>"
                exit 1
            fi
            start_plugin "$2"
            ;;
        "stop")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 stop <plugin_name>"
                exit 1
            fi
            stop_plugin "$2"
            ;;
        "status")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 status <plugin_name>"
                exit 1
            fi
            check_plugin_health "$2"
            ;;
        "monitor")
            monitor_plugins
            ;;
        *)
            echo "Usage: $0 {init|list|install|uninstall|start|stop|status|monitor} [args]"
            exit 1
            ;;
    esac
}

main "$@"