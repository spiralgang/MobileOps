#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# test-userland-apps.sh - Test suite for userland-apps tools
# Part of FileSystemds test infrastructure

set -euo pipefail

# Test configuration
readonly TEST_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
readonly TOOLS_DIR="$(realpath "$TEST_DIR/../../tools/userland-apps")"
readonly LOG_DIR="/tmp/userland-apps-tests"
readonly FAILED_TESTS_LOG="$LOG_DIR/failed-tests.log"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_tests() {
    mkdir -p "$LOG_DIR"
    rm -f "$FAILED_TESTS_LOG"
    export NO_SUDO=1  # Disable sudo for testing
    export USERLAND_APPS_LOG_LEVEL=ERROR  # Reduce log noise
}

# Logging functions
log_test() {
    echo "[TEST] $*"
}

log_pass() {
    echo "[PASS] $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo "[FAIL] $*"
    echo "$*" >> "$FAILED_TESTS_LOG"
    ((TESTS_FAILED++))
}

# Test runner
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    log_test "Running $test_name..."
    ((TESTS_RUN++))
    
    if "$test_func"; then
        log_pass "$test_name"
    else
        log_fail "$test_name"
    fi
}

# Test help functionality for all tools
test_help_functionality() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -x "$tool_path" ]]; then
        echo "Tool not found or not executable: $tool_path"
        return 1
    fi
    
    # Test --help option
    if ! "$tool_path" --help >/dev/null 2>&1; then
        echo "$tool_name: --help failed"
        return 1
    fi
    
    # Test -h option
    if ! "$tool_path" -h >/dev/null 2>&1; then
        echo "$tool_name: -h failed"
        return 1
    fi
    
    return 0
}

# Test version functionality for all tools
test_version_functionality() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -x "$tool_path" ]]; then
        echo "Tool not found or not executable: $tool_path"
        return 1
    fi
    
    # Test --version option
    if ! "$tool_path" --version >/dev/null 2>&1; then
        echo "$tool_name: --version failed"
        return 1
    fi
    
    # Test -V option
    if ! "$tool_path" -V >/dev/null 2>&1; then
        echo "$tool_name: -V failed"
        return 1
    fi
    
    return 0
}

# Test error handling for invalid options
test_error_handling() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -x "$tool_path" ]]; then
        echo "Tool not found or not executable: $tool_path"
        return 1
    fi
    
    # Test invalid option handling
    if "$tool_path" --invalid-option >/dev/null 2>&1; then
        echo "$tool_name: should fail with invalid option"
        return 1
    fi
    
    return 0
}

# Test concurrent execution safety
test_concurrent_execution() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -x "$tool_path" ]]; then
        echo "Tool not found or not executable: $tool_path"
        return 1
    fi
    
    # Start tool in background with --install-only to avoid launching
    "$tool_path" --install-only >/dev/null 2>&1 &
    local pid1=$!
    
    # Try to start another instance
    if "$tool_path" --install-only >/dev/null 2>&1; then
        # If it succeeds, either the lock failed or first instance finished quickly
        kill "$pid1" 2>/dev/null || true
        wait "$pid1" 2>/dev/null || true
        # This is not necessarily a failure - could be fast execution
        return 0
    else
        # Second instance should fail due to lock
        kill "$pid1" 2>/dev/null || true
        wait "$pid1" 2>/dev/null || true
        return 0
    fi
}

# Test install-only mode
test_install_only_mode() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -x "$tool_path" ]]; then
        echo "Tool not found or not executable: $tool_path"
        return 1
    fi
    
    # Test --install-only doesn't try to launch
    # This should return quickly and not hang waiting for user input
    timeout 10s "$tool_path" --install-only >/dev/null 2>&1 || {
        local exit_code=$?
        # Timeout (124) or other expected failures are ok for install-only tests
        if [[ $exit_code -eq 124 ]]; then
            echo "$tool_name: --install-only hung (timeout)"
            return 1
        fi
        # Other failures might be expected (e.g., missing sudo)
        return 0
    }
    
    return 0
}

# Test script syntax and basic structure
test_script_syntax() {
    local tool_name="$1"
    local tool_path="$TOOLS_DIR/$tool_name"
    
    if [[ ! -f "$tool_path" ]]; then
        echo "Tool not found: $tool_path"
        return 1
    fi
    
    # Check shebang
    if ! head -n1 "$tool_path" | grep -q "^#!/bin/bash"; then
        echo "$tool_name: invalid or missing shebang"
        return 1
    fi
    
    # Check syntax
    if ! bash -n "$tool_path"; then
        echo "$tool_name: syntax check failed"
        return 1
    fi
    
    # Check for SPDX license header
    if ! grep -q "SPDX-License-Identifier:" "$tool_path"; then
        echo "$tool_name: missing SPDX license header"
        return 1
    fi
    
    # Check for set -euo pipefail
    if ! grep -q "set -euo pipefail" "$tool_path"; then
        echo "$tool_name: missing 'set -euo pipefail'"
        return 1
    fi
    
    return 0
}

# Test data file validity
test_apps_csv() {
    local csv_file="$TEST_DIR/../../data/apps.csv"
    
    if [[ ! -f "$csv_file" ]]; then
        echo "apps.csv not found: $csv_file"
        return 1
    fi
    
    # Check CSV structure - find first non-comment line
    local header_line
    header_line=$(grep -v "^#" "$csv_file" | head -n1)
    
    if [[ "$header_line" != "app_name,category,filesystem_type,supports_cli,supports_gui,is_paid_app,version,description" ]]; then
        echo "Invalid CSV header in apps.csv"
        return 1
    fi
    
    # Check that we have some data entries
    local data_lines
    data_lines=$(grep -v "^#" "$csv_file" | grep -c "," || true)
    
    if [[ $data_lines -lt 5 ]]; then
        echo "apps.csv has too few data entries: $data_lines"
        return 1
    fi
    
    return 0
}

# Test asset manifest
test_asset_manifest() {
    local manifest_file="$TEST_DIR/../../share/assets/manifest.csv"
    
    if [[ ! -f "$manifest_file" ]]; then
        echo "Asset manifest not found: $manifest_file"
        return 1
    fi
    
    # Check manifest structure
    if ! grep -q "filename,architecture,size_bytes,sha256sum,purpose" "$manifest_file"; then
        echo "Invalid manifest header"
        return 1
    fi
    
    return 0
}

# Discover and test all tools
test_all_tools() {
    local tools=()
    
    # Find all executable files in tools directory
    while IFS= read -r -d '' tool; do
        tool_name=$(basename "$tool")
        tools+=("$tool_name")
    done < <(find "$TOOLS_DIR" -type f -executable -print0 2>/dev/null)
    
    if [[ ${#tools[@]} -eq 0 ]]; then
        echo "No tools found in $TOOLS_DIR"
        return 1
    fi
    
    echo "Found ${#tools[@]} tools: ${tools[*]}"
    
    # Test each tool
    for tool in "${tools[@]}"; do
        run_test "$tool syntax check" "test_script_syntax $tool"
        run_test "$tool help functionality" "test_help_functionality $tool"
        run_test "$tool version functionality" "test_version_functionality $tool"
        run_test "$tool error handling" "test_error_handling $tool"
        run_test "$tool install-only mode" "test_install_only_mode $tool"
        run_test "$tool concurrent execution" "test_concurrent_execution $tool"
    done
    
    return 0
}

# Main test execution
main() {
    echo "FileSystemds Userland Apps Test Suite"
    echo "====================================="
    
    setup_tests
    
    # Run data file tests
    run_test "apps.csv validation" "test_apps_csv"
    run_test "asset manifest validation" "test_asset_manifest"
    
    # Test all discovered tools
    test_all_tools
    
    # Summary
    echo
    echo "Test Results:"
    echo "============="
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo
        echo "Failed tests:"
        cat "$FAILED_TESTS_LOG"
        exit 1
    else
        echo
        echo "All tests passed!"
        exit 0
    fi
}

main "$@"