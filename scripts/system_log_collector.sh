#!/bin/bash

# System Log Collector for MobileOps Platform
# Centralized logging and log analysis for the platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/system_log_collector.log"
LOG_CONFIG_DIR="/etc/mobileops/logging"
COLLECTED_LOGS_DIR="/var/log/mobileops/collected"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

collect_system_logs() {
    log "INFO: Collecting system logs"
    
    local output_dir="$COLLECTED_LOGS_DIR/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    # Collect systemd journal
    if command -v journalctl >/dev/null; then
        journalctl --since="24 hours ago" > "$output_dir/journal.log" 2>/dev/null || true
        log "INFO: Collected journal logs"
    fi
    
    # Collect syslog
    if [[ -f "/var/log/syslog" ]]; then
        tail -n 1000 /var/log/syslog > "$output_dir/syslog" 2>/dev/null || true
    fi
    
    # Collect kernel messages
    if [[ -f "/var/log/kern.log" ]]; then
        tail -n 500 /var/log/kern.log > "$output_dir/kern.log" 2>/dev/null || true
    fi
    
    # Collect authentication logs
    if [[ -f "/var/log/auth.log" ]]; then
        tail -n 500 /var/log/auth.log > "$output_dir/auth.log" 2>/dev/null || true
    fi
    
    log "INFO: System logs collected to: $output_dir"
}

collect_mobileops_logs() {
    log "INFO: Collecting MobileOps specific logs"
    
    local output_dir="$COLLECTED_LOGS_DIR/mobileops_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    # Collect all MobileOps logs
    if [[ -d "/var/log/mobileops" ]]; then
        find /var/log/mobileops -name "*.log" -type f | while read -r logfile; do
            local basename=$(basename "$logfile")
            cp "$logfile" "$output_dir/$basename" 2>/dev/null || true
        done
    fi
    
    # Collect container logs
    if [[ -d "/var/run/mobileops" ]]; then
        find /var/run/mobileops -name "*.log" -type f | while read -r logfile; do
            local basename=$(basename "$logfile")
            cp "$logfile" "$output_dir/runtime_$basename" 2>/dev/null || true
        done
    fi
    
    log "INFO: MobileOps logs collected to: $output_dir"
}

analyze_logs() {
    local log_dir="$1"
    log "INFO: Analyzing logs in: $log_dir"
    
    local analysis_file="$log_dir/analysis.txt"
    
    {
        echo "=== LOG ANALYSIS REPORT ==="
        echo "Generated: $(date)"
        echo "Log Directory: $log_dir"
        echo ""
        
        # Error analysis
        echo "=== ERROR ANALYSIS ==="
        find "$log_dir" -name "*.log" -type f | while read -r logfile; do
            local error_count=$(grep -i "error" "$logfile" 2>/dev/null | wc -l || echo "0")
            echo "$(basename "$logfile"): $error_count errors"
        done
        echo ""
        
        # Warning analysis
        echo "=== WARNING ANALYSIS ==="
        find "$log_dir" -name "*.log" -type f | while read -r logfile; do
            local warning_count=$(grep -i "warn" "$logfile" 2>/dev/null | wc -l || echo "0")
            echo "$(basename "$logfile"): $warning_count warnings"
        done
        echo ""
        
        # Recent critical events
        echo "=== RECENT CRITICAL EVENTS ==="
        find "$log_dir" -name "*.log" -type f -exec grep -i "critical\|fatal\|panic" {} + 2>/dev/null | tail -10 || echo "No critical events found"
        echo ""
        
        # Resource usage patterns
        echo "=== RESOURCE USAGE PATTERNS ==="
        find "$log_dir" -name "*.log" -type f -exec grep -i "memory\|cpu\|disk" {} + 2>/dev/null | tail -10 || echo "No resource usage data found"
        
    } > "$analysis_file"
    
    log "INFO: Analysis completed: $analysis_file"
}

monitor_real_time() {
    log "INFO: Starting real-time log monitoring"
    
    # Monitor MobileOps logs
    local monitor_logs=(
        "/var/log/mobileops/platform_launcher.log"
        "/var/log/mobileops/ai_core_manager.log"
        "/var/log/mobileops/network_configure.log"
    )
    
    echo "Monitoring logs (Ctrl+C to stop):"
    for logfile in "${monitor_logs[@]}"; do
        echo "  - $logfile"
    done
    echo ""
    
    # Use multitail if available, otherwise use tail
    if command -v multitail >/dev/null; then
        multitail "${monitor_logs[@]}" 2>/dev/null || true
    else
        tail -f "${monitor_logs[@]}" 2>/dev/null || true
    fi
}

rotate_logs() {
    log "INFO: Rotating logs"
    
    local max_size="${1:-100M}"
    local max_age="${2:-7}"  # days
    
    # Rotate large log files
    find /var/log/mobileops -name "*.log" -size "+$max_size" | while read -r logfile; do
        log "INFO: Rotating large log file: $logfile"
        gzip "$logfile"
        mv "${logfile}.gz" "${logfile}.$(date +%Y%m%d).gz"
        touch "$logfile"
    done
    
    # Remove old log files
    find /var/log/mobileops -name "*.log.*.gz" -mtime "+$max_age" -delete
    find "$COLLECTED_LOGS_DIR" -type d -mtime "+$max_age" -exec rm -rf {} + 2>/dev/null || true
    
    log "INFO: Log rotation completed"
}

export_logs() {
    local export_format="${1:-tar}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local export_file="/tmp/mobileops_logs_$timestamp"
    
    log "INFO: Exporting logs in $export_format format"
    
    case "$export_format" in
        "tar")
            tar -czf "${export_file}.tar.gz" -C /var/log mobileops/ 2>/dev/null || true
            echo "Logs exported to: ${export_file}.tar.gz"
            ;;
        "zip")
            if command -v zip >/dev/null; then
                zip -r "${export_file}.zip" /var/log/mobileops/ >/dev/null 2>&1 || true
                echo "Logs exported to: ${export_file}.zip"
            else
                log "ERROR: zip command not available"
                return 1
            fi
            ;;
        *)
            log "ERROR: Unsupported export format: $export_format"
            return 1
            ;;
    esac
}

search_logs() {
    local search_term="$1"
    local time_range="${2:-24h}"
    
    log "INFO: Searching for '$search_term' in logs (last $time_range)"
    
    # Convert time range to find format
    local find_time=""
    case "$time_range" in
        *h) find_time="-mmin -$((${time_range%h} * 60))" ;;
        *d) find_time="-mtime -${time_range%d}" ;;
        *) find_time="-mtime -1" ;;
    esac
    
    find /var/log/mobileops -name "*.log" $find_time | while read -r logfile; do
        local matches=$(grep -c "$search_term" "$logfile" 2>/dev/null || echo "0")
        if [[ $matches -gt 0 ]]; then
            echo "=== $logfile ($matches matches) ==="
            grep --color=always "$search_term" "$logfile" | head -5
            echo ""
        fi
    done
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$LOG_CONFIG_DIR" "$COLLECTED_LOGS_DIR"
    log "INFO: System Log Collector started"
    
    case "${1:-collect}" in
        "collect")
            collect_system_logs
            collect_mobileops_logs
            ;;
        "analyze")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 analyze <log_directory>"
                exit 1
            fi
            analyze_logs "$2"
            ;;
        "monitor")
            monitor_real_time
            ;;
        "rotate")
            rotate_logs "${2:-100M}" "${3:-7}"
            ;;
        "export")
            export_logs "${2:-tar}"
            ;;
        "search")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 search <search_term> [time_range]"
                exit 1
            fi
            search_logs "$2" "${3:-24h}"
            ;;
        *)
            echo "Usage: $0 {collect|analyze|monitor|rotate|export|search} [args]"
            exit 1
            ;;
    esac
}

main "$@"