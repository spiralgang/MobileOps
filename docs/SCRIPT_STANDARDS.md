---
title: Script Standards and Guidelines
category: Platform Documentation
layout: default
SPDX-License-Identifier: LGPL-2.1-or-later
---

# MobileOps Script Standards and Guidelines

## Overview

This document establishes coding standards, best practices, and guidelines for developing and maintaining scripts within the MobileOps platform. Following these standards ensures consistency, maintainability, and reliability across all platform components.

## General Script Standards

### File Organization

```bash
# Standard script header
#!/bin/bash

# Script description and purpose
# Author: Developer Name
# Version: 1.0.0
# Last Modified: YYYY-MM-DD

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Constants and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/$(basename "$0" .sh).log"
CONFIG_DIR="/etc/mobileops"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Main function
main() {
    # Script logic here
    log "INFO: Script started"
    # ...
    log "INFO: Script completed"
}

# Execute main function with all arguments
main "$@"
```

### Error Handling

```bash
# Error handling function
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log "ERROR: $message"
    exit "$exit_code"
}

# Usage validation
validate_args() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <required_arg> [optional_arg]"
        echo ""
        echo "Description: Brief description of what this script does"
        echo ""
        echo "Arguments:"
        echo "  required_arg    Description of required argument"
        echo "  optional_arg    Description of optional argument"
        exit 1
    fi
}

# Dependency checking
check_dependencies() {
    local dependencies=("curl" "jq" "docker")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error_exit "Required dependency not found: $dep"
        fi
    done
}
```

## Naming Conventions

### Script Names
- Use descriptive, action-oriented names
- Use underscores to separate words
- Use `.sh` extension for shell scripts
- Examples: `platform_launcher.sh`, `ai_core_manager.sh`

### Variable Names
```bash
# Constants (uppercase with underscores)
readonly SCRIPT_VERSION="1.0.0"
readonly DEFAULT_TIMEOUT=300
readonly CONFIG_FILE="/etc/mobileops/config.conf"

# Global variables (lowercase with underscores)
script_name="$(basename "$0")"
current_user="$(whoami)"
temp_dir="/tmp/${script_name}_$$"

# Local variables (lowercase with underscores)
process_data() {
    local input_file="$1"
    local output_dir="$2"
    local processing_mode="${3:-default}"
    
    # Function logic
}
```

### Function Names
```bash
# Use descriptive verb-noun combinations
start_service() { }
stop_service() { }
check_service_status() { }
validate_configuration() { }
generate_report() { }

# Private functions (prefix with underscore)
_internal_helper() { }
_parse_config_file() { }
_cleanup_temp_files() { }
```

## Code Structure Standards

### Function Organization
```bash
#!/bin/bash

# Global variables and constants
readonly SCRIPT_VERSION="1.0.0"

# Utility functions
log() { }
error_exit() { }
cleanup() { }

# Configuration functions
load_configuration() { }
validate_configuration() { }

# Core business logic functions
start_component() { }
stop_component() { }
monitor_component() { }

# Helper functions
_internal_helper() { }
_another_helper() { }

# Main execution flow
main() {
    # Argument validation
    validate_args "$@"
    
    # Setup
    load_configuration
    check_dependencies
    
    # Main logic
    case "${1:-help}" in
        "start")    start_component ;;
        "stop")     stop_component ;;
        "status")   monitor_component ;;
        *)          show_usage ;;
    esac
    
    # Cleanup
    cleanup
}

# Execute main with all arguments
main "$@"
```

### Command-Line Interface Standards

```bash
show_usage() {
    cat << EOF
Usage: $0 {start|stop|restart|status|configure} [options]

DESCRIPTION
    MobileOps Component Manager
    Manages the lifecycle of platform components

COMMANDS
    start       Start the component service
    stop        Stop the component service  
    restart     Restart the component service
    status      Show component status
    configure   Configure component settings

OPTIONS
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    -c, --config FILE   Use specific configuration file
    -t, --timeout SEC   Set operation timeout (default: 300)
    --dry-run          Show what would be done without executing

EXAMPLES
    $0 start
    $0 stop --verbose
    $0 configure --config /etc/custom.conf
    $0 status --timeout 60

EOF
}

# Argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done
}
```

## Logging Standards

### Log Levels and Format
```bash
# Standardized logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_entry="[$timestamp] [$level] [$$] $message"
    
    echo "$log_entry" | tee -a "$LOG_FILE"
    
    # Also log to syslog for important messages
    case "$level" in
        "ERROR"|"CRITICAL")
            logger -p daemon.err "$log_entry"
            ;;
        "WARN")
            logger -p daemon.warning "$log_entry"
            ;;
        "INFO")
            logger -p daemon.info "$log_entry"
            ;;
    esac
}

# Convenience functions
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { [[ "${DEBUG:-}" == "true" ]] && log "DEBUG" "$@"; }
```

### Log File Management
```bash
# Log rotation and cleanup
manage_log_files() {
    local log_dir="$(dirname "$LOG_FILE")"
    local log_name="$(basename "$LOG_FILE" .log)"
    
    # Create log directory if it doesn't exist
    mkdir -p "$log_dir"
    
    # Rotate log if it's too large (>10MB)
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -c%s "$LOG_FILE") -gt 10485760 ]]; then
        local timestamp="$(date +%Y%m%d_%H%M%S)"
        mv "$LOG_FILE" "${log_dir}/${log_name}_${timestamp}.log"
        gzip "${log_dir}/${log_name}_${timestamp}.log"
        touch "$LOG_FILE"
    fi
    
    # Clean old log files (older than 30 days)
    find "$log_dir" -name "${log_name}_*.log.gz" -mtime +30 -delete
}
```

## Configuration Management

### Configuration File Standards
```bash
# Configuration loading with defaults
load_configuration() {
    local config_file="${CONFIG_FILE:-/etc/mobileops/default.conf}"
    
    # Set default values
    TIMEOUT="${TIMEOUT:-300}"
    LOG_LEVEL="${LOG_LEVEL:-INFO}"
    RETRY_COUNT="${RETRY_COUNT:-3}"
    
    # Load configuration file if it exists
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from: $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
    else
        log_warn "Configuration file not found: $config_file"
    fi
    
    # Override with environment variables
    TIMEOUT="${MOBILEOPS_TIMEOUT:-$TIMEOUT}"
    LOG_LEVEL="${MOBILEOPS_LOG_LEVEL:-$LOG_LEVEL}"
}

# Configuration validation
validate_configuration() {
    # Validate required settings
    [[ -n "$REQUIRED_SETTING" ]] || error_exit "REQUIRED_SETTING not configured"
    
    # Validate numeric values
    if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
        error_exit "TIMEOUT must be a positive integer"
    fi
    
    # Validate file paths
    if [[ -n "$DATA_DIR" ]] && [[ ! -d "$DATA_DIR" ]]; then
        error_exit "DATA_DIR does not exist: $DATA_DIR"
    fi
}
```

### Environment Variable Standards
```bash
# Environment variable naming convention
MOBILEOPS_LOG_LEVEL="${MOBILEOPS_LOG_LEVEL:-INFO}"
MOBILEOPS_CONFIG_DIR="${MOBILEOPS_CONFIG_DIR:-/etc/mobileops}"
MOBILEOPS_DATA_DIR="${MOBILEOPS_DATA_DIR:-/var/lib/mobileops}"
MOBILEOPS_CACHE_DIR="${MOBILEOPS_CACHE_DIR:-/var/cache/mobileops}"
MOBILEOPS_RUN_DIR="${MOBILEOPS_RUN_DIR:-/var/run/mobileops}"

# Support for debug mode
MOBILEOPS_DEBUG="${MOBILEOPS_DEBUG:-false}"
MOBILEOPS_VERBOSE="${MOBILEOPS_VERBOSE:-false}"
```

## Testing Standards

### Unit Testing for Scripts
```bash
# Test framework for scripts
run_tests() {
    local test_count=0
    local pass_count=0
    local fail_count=0
    
    # Test function template
    test_function_name() {
        local test_name="Test Description"
        ((test_count++))
        
        # Test setup
        local expected="expected_value"
        local actual
        
        # Execute test
        actual="$(function_to_test "test_input")"
        
        # Verify result
        if [[ "$actual" == "$expected" ]]; then
            echo "✓ $test_name"
            ((pass_count++))
        else
            echo "✗ $test_name - Expected: $expected, Actual: $actual"
            ((fail_count++))
        fi
    }
    
    # Run all tests
    test_function_name
    # ... more tests
    
    # Report results
    echo "Tests: $test_count, Passed: $pass_count, Failed: $fail_count"
    [[ $fail_count -eq 0 ]]
}
```

### Integration Testing
```bash
# Integration test template
run_integration_tests() {
    log_info "Starting integration tests"
    
    # Setup test environment
    setup_test_environment
    
    # Test component interaction
    test_component_startup
    test_component_communication
    test_component_shutdown
    
    # Cleanup test environment
    cleanup_test_environment
    
    log_info "Integration tests completed"
}

setup_test_environment() {
    # Create temporary directories
    TEST_DIR="$(mktemp -d)"
    export MOBILEOPS_CONFIG_DIR="$TEST_DIR/config"
    export MOBILEOPS_DATA_DIR="$TEST_DIR/data"
    
    # Create test configuration
    mkdir -p "$MOBILEOPS_CONFIG_DIR"
    cat > "$MOBILEOPS_CONFIG_DIR/test.conf" <<EOF
TIMEOUT=60
LOG_LEVEL=DEBUG
TEST_MODE=true
EOF
}
```

## Security Standards

### Input Validation
```bash
# Input sanitization
sanitize_input() {
    local input="$1"
    local max_length="${2:-255}"
    
    # Remove dangerous characters
    input="${input//[;&|`\$]/}"
    
    # Limit length
    input="${input:0:$max_length}"
    
    echo "$input"
}

# Path validation
validate_path() {
    local path="$1"
    local allow_relative="${2:-false}"
    
    # Check for path traversal
    if [[ "$path" =~ \.\. ]]; then
        error_exit "Path traversal detected: $path"
    fi
    
    # Check for absolute path requirement
    if [[ "$allow_relative" != "true" ]] && [[ "$path" != /* ]]; then
        error_exit "Absolute path required: $path"
    fi
}

# Command injection prevention
safe_execute() {
    local command=("$@")
    
    # Use array for command execution to prevent injection
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Would execute: ${command[*]}"
    else
        "${command[@]}" || error_exit "Command failed: ${command[*]}"
    fi
}
```

### Secure File Operations
```bash
# Secure temporary file creation
create_temp_file() {
    local prefix="${1:-mobileops}"
    local temp_file
    
    temp_file="$(mktemp "/tmp/${prefix}.XXXXXX")" || error_exit "Failed to create temporary file"
    chmod 600 "$temp_file"
    echo "$temp_file"
}

# Secure file permissions
set_secure_permissions() {
    local file="$1"
    local permissions="${2:-644}"
    
    if [[ -f "$file" ]]; then
        chmod "$permissions" "$file"
        chown root:root "$file"
    fi
}
```

## Performance Standards

### Efficient Script Design
```bash
# Use built-in commands when possible
# Good
if [[ -f "$file" ]]; then
    # ...
fi

# Avoid external commands for simple operations
# Bad
if test -f "$file"; then
    # ...
fi

# Use parameter expansion instead of external commands
# Good
filename="${path##*/}"
dirname="${path%/*}"

# Bad
filename="$(basename "$path")"
dirname="$(dirname "$path")"
```

### Resource Management
```bash
# Cleanup function for resource management
cleanup() {
    local exit_code=$?
    
    # Remove temporary files
    [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    
    # Kill background processes
    [[ -n "${BACKGROUND_PID:-}" ]] && kill "$BACKGROUND_PID" 2>/dev/null || true
    
    # Close file descriptors
    exec 3<&- 4<&- 2>/dev/null || true
    
    exit $exit_code
}

# Set up cleanup trap
trap cleanup EXIT INT TERM
```

## Documentation Standards

### Script Documentation
```bash
#!/bin/bash
#
# MobileOps Component Manager
#
# Description:
#   Manages the lifecycle of MobileOps platform components including
#   startup, shutdown, configuration, and monitoring.
#
# Author: MobileOps Team
# Version: 1.2.0
# License: LGPL-2.1-or-later
#
# Dependencies:
#   - curl (for API communication)
#   - jq (for JSON processing)
#   - systemctl (for service management)
#
# Configuration:
#   /etc/mobileops/component.conf - Main configuration file
#   MOBILEOPS_* environment variables override config file settings
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Configuration error
#   3 - Dependency error
#   4 - Service error
#
# Examples:
#   ./component_manager.sh start
#   ./component_manager.sh stop --verbose
#   ./component_manager.sh status --config /etc/custom.conf
#
```

### Function Documentation
```bash
#
# Process application data with specified transformations
#
# Arguments:
#   $1 - input_file: Path to input data file (required)
#   $2 - output_dir: Output directory path (required)
#   $3 - format: Output format [json|xml|csv] (optional, default: json)
#   $4 - compress: Enable compression [true|false] (optional, default: false)
#
# Returns:
#   0 - Success
#   1 - Invalid input file
#   2 - Invalid output directory
#   3 - Processing error
#
# Example:
#   process_data "/path/to/input.txt" "/tmp/output" "json" "true"
#
process_data() {
    local input_file="$1"
    local output_dir="$2"
    local format="${3:-json}"
    local compress="${4:-false}"
    
    # Function implementation
}
```

## Code Quality Standards

### ShellCheck Compliance
```bash
# Enable ShellCheck directives
# shellcheck shell=bash
# shellcheck disable=SC2034  # Variable appears unused

# Proper quoting
echo "User home: $HOME"           # Good
echo "Files: ${files[*]}"        # Good
echo User home: $HOME             # Bad - missing quotes

# Array usage
files=("file1.txt" "file2.txt")   # Good
files="file1.txt file2.txt"       # Bad - string instead of array
```

### Best Practices Checklist

1. **Script Header**
   - [ ] Proper shebang line
   - [ ] Script description and metadata
   - [ ] Error handling flags (`set -euo pipefail`)

2. **Functions**
   - [ ] Clear, descriptive names
   - [ ] Proper parameter handling
   - [ ] Input validation
   - [ ] Error handling

3. **Variables**
   - [ ] Consistent naming convention
   - [ ] Proper quoting
   - [ ] Readonly for constants
   - [ ] Local scope where appropriate

4. **Error Handling**
   - [ ] Comprehensive error checking
   - [ ] Meaningful error messages
   - [ ] Proper exit codes
   - [ ] Cleanup on exit

5. **Documentation**
   - [ ] Script purpose and usage
   - [ ] Function documentation
   - [ ] Configuration requirements
   - [ ] Example usage

6. **Testing**
   - [ ] Unit tests for functions
   - [ ] Integration tests
   - [ ] Error scenario testing
   - [ ] Performance testing

## Maintenance Standards

### Version Management
```bash
# Version information
readonly SCRIPT_VERSION="1.2.0"
readonly SCRIPT_BUILD="$(date +%Y%m%d)"
readonly SCRIPT_COMMIT="${GIT_COMMIT:-unknown}"

show_version() {
    cat << EOF
$(basename "$0") version $SCRIPT_VERSION (build $SCRIPT_BUILD)
Commit: $SCRIPT_COMMIT
MobileOps Platform $(cat /etc/mobileops/version 2>/dev/null || echo "unknown")
EOF
}
```

### Change Management
```bash
# Change log header
#
# Changelog:
#   1.2.0 (2024-01-15)
#     - Added configuration validation
#     - Improved error handling
#     - Added support for custom timeouts
#   1.1.0 (2024-01-01)
#     - Initial implementation
#     - Basic component management
#
```

## Platform Integration

### Common MobileOps Patterns
```bash
# Standard MobileOps script template
source_mobileops_common() {
    # Common directory paths
    readonly MOBILEOPS_HOME="/opt/mobileops"
    readonly MOBILEOPS_CONFIG="/etc/mobileops"
    readonly MOBILEOPS_DATA="/var/lib/mobileops"
    readonly MOBILEOPS_LOGS="/var/log/mobileops"
    readonly MOBILEOPS_RUN="/var/run/mobileops"
    
    # Load common functions
    if [[ -f "$MOBILEOPS_HOME/lib/common.sh" ]]; then
        # shellcheck source=/dev/null
        source "$MOBILEOPS_HOME/lib/common.sh"
    fi
}

# Integration with other platform components
call_component() {
    local component="$1"
    local action="$2"
    shift 2
    
    if [[ -x "$SCRIPT_DIR/${component}.sh" ]]; then
        "$SCRIPT_DIR/${component}.sh" "$action" "$@"
    else
        error_exit "Component not found: $component"
    fi
}
```

This comprehensive script standards document ensures all MobileOps platform scripts follow consistent, secure, and maintainable patterns. Following these guidelines will improve code quality, reduce bugs, and make the platform more reliable and easier to maintain.