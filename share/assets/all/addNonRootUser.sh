#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# addNonRootUser.sh - Create non-root user accounts
# Part of FileSystemds userland-apps asset collection
#
# Creates a non-root user account with configurable username and password.
# Sanitized version with improved security and validation.

set -euo pipefail

# Configuration with secure defaults
readonly DEFAULT_USERNAME="user"
readonly DEFAULT_PASSWORD="change_me_please"
readonly DEFAULT_UID="2000"
readonly DEFAULT_SHELL="/bin/bash"

# Input validation and sanitization
validate_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        echo "ERROR: Invalid username. Must be lowercase, start with letter, max 32 chars" >&2
        return 1
    fi
    return 0
}

validate_uid() {
    local uid="$1"
    if [[ ! "$uid" =~ ^[0-9]+$ ]] || [[ "$uid" -lt 1000 ]] || [[ "$uid" -gt 65533 ]]; then
        echo "ERROR: Invalid UID. Must be numeric between 1000-65533" >&2
        return 1
    fi
    return 0
}

# Main user creation function
create_user() {
    local username="${INITIAL_USERNAME:-$DEFAULT_USERNAME}"
    local password="${INITIAL_PASSWORD:-$DEFAULT_PASSWORD}"
    local uid="${INITIAL_UID:-$DEFAULT_UID}"
    local shell="${INITIAL_SHELL:-$DEFAULT_SHELL}"
    
    # Validate inputs
    validate_username "$username" || exit 1
    validate_uid "$uid" || exit 1
    
    # Check if user already exists
    if id "$username" >/dev/null 2>&1; then
        echo "INFO: User '$username' already exists" >&2
        return 0
    fi
    
    # Check if UID is already in use
    if getent passwd "$uid" >/dev/null 2>&1; then
        echo "ERROR: UID $uid is already in use" >&2
        return 1
    fi
    
    # Ensure the shell exists
    if [[ ! -x "$shell" ]]; then
        echo "WARN: Shell '$shell' not found, using /bin/sh" >&2
        shell="/bin/sh"
    fi
    
    # Add shell to /etc/shells if needed
    if ! grep -Fxq "$shell" /etc/shells 2>/dev/null; then
        echo "$shell" >> /etc/shells
    fi
    
    # Create user with home directory
    echo "INFO: Creating user '$username' with UID $uid" >&2
    if ! useradd "$username" -s "$shell" -m -u "$uid"; then
        echo "ERROR: Failed to create user '$username'" >&2
        return 1
    fi
    
    # Set password securely
    if ! echo "$username:$password" | chpasswd; then
        echo "ERROR: Failed to set password for user '$username'" >&2
        userdel -r "$username" 2>/dev/null || true
        return 1
    fi
    
    # Set proper shell
    if ! chsh -s "$shell" "$username"; then
        echo "WARN: Failed to set shell for user '$username'" >&2
    fi
    
    echo "INFO: User '$username' created successfully" >&2
    return 0
}

# Show usage information
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Creates a non-root user account with configurable settings.

ENVIRONMENT VARIABLES:
    INITIAL_USERNAME     Username to create (default: $DEFAULT_USERNAME)
    INITIAL_PASSWORD     Password for user (default: $DEFAULT_PASSWORD)
    INITIAL_UID          User ID number (default: $DEFAULT_UID)
    INITIAL_SHELL        Login shell (default: $DEFAULT_SHELL)

OPTIONS:
    -h, --help          Show this help message

EXAMPLES:
    INITIAL_USERNAME=alice INITIAL_PASSWORD=secret123 $0
    INITIAL_UID=3000 $0

SECURITY NOTES:
    - Usernames are validated for security
    - UIDs must be in safe range (1000-65533)
    - Passwords should be changed after creation
    - Script requires root privileges

EOF
}

# Main execution
main() {
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Check for root privileges
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: This script must be run as root" >&2
        exit 1
    fi
    
    # Warn about default password
    if [[ "${INITIAL_PASSWORD:-$DEFAULT_PASSWORD}" == "$DEFAULT_PASSWORD" ]]; then
        echo "WARN: Using default password. Change it immediately after creation!" >&2
    fi
    
    create_user
}

main "$@"