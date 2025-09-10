# Userland Apps

The FileSystemds userland-apps toolset provides secure, robust installation and management of common applications and development environments. This system replaces the original UserlAsServer app installation scripts with production-ready, modern implementations.

## Overview

The userland-apps system consists of:

- **Installation Tools**: Modern, secure CLI tools for installing and launching applications
- **Metadata Management**: CSV-based application catalog with validation
- **Asset Management**: Sanitized system utilities and resources
- **Test Suite**: Comprehensive testing for reliability and security

## Quick Start

### Installing and Running Applications

```bash
# Install and launch R statistical computing environment
./tools/userland-apps/r-lang

# Install Git GUI interface
./tools/userland-apps/git-gui

# Install and play Zork text adventure game  
./tools/userland-apps/zork

# Install only, don't launch
./tools/userland-apps/r-lang --install-only

# Force reinstallation
./tools/userland-apps/git-gui --force-install
```

### Testing

```bash
# Run the complete test suite
./tests/userland-apps/test-userland-apps.sh

# Test specific functionality
./tools/userland-apps/r-lang --help
./tools/userland-apps/git-gui --version
```

## Architecture

### Tools Directory Structure

```
tools/userland-apps/
├── r-lang          # R statistical computing language
├── git-gui         # Git GUI interface
├── zork            # Zork text adventure game
└── ...             # Additional application installers
```

### Data Files

```
data/
└── apps.csv        # Application metadata catalog
```

### Assets

```
share/assets/
├── manifest.csv    # Asset inventory and checksums
├── all/           # Cross-platform assets
├── x86_64/        # x86_64 specific binaries
├── arm64/         # ARM64 specific binaries
└── ...            # Other architectures
```

## Features

### Security

- **Input Validation**: All user inputs are validated and sanitized
- **Privilege Escalation**: Secure sudo handling with proper checks
- **Concurrent Safety**: Lock files prevent multiple instances
- **Error Handling**: Comprehensive error handling and logging
- **Asset Verification**: Checksums and validation for all assets

### Reliability

- **Idempotent Operations**: Scripts can be run multiple times safely
- **OS Detection**: Automatic detection of Linux distribution and package manager
- **Dependency Management**: Automatic installation of required packages
- **Logging**: Detailed logging for debugging and auditing

### Usability

- **Consistent Interface**: All tools follow the same command-line patterns
- **Help System**: Built-in help and usage information
- **Environment Detection**: Automatic GUI/CLI environment detection
- **Installation Verification**: Post-installation verification steps

## Tool Development

### Creating New Tools

All userland-apps tools should follow these standards:

1. **Script Header**:
```bash
#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# tool-name - Brief Description
# Part of FileSystemds userland-apps toolset

set -euo pipefail
```

2. **Required Functions**:
- `show_help()`: Display usage information
- `show_version()`: Display version information  
- `main()`: Primary execution function with argument parsing

3. **Required Features**:
- Lock file for concurrent execution safety
- Logging to `/var/log/userland-apps/`
- OS detection and package manager support
- Error handling with proper exit codes
- Support for `--help`, `--version`, `--install-only` options

4. **Security Requirements**:
- Input validation and sanitization
- Secure privilege escalation
- No hardcoded credentials or paths
- Safe file operations

### Example Tool Structure

```bash
#!/bin/bash
set -euo pipefail

readonly SCRIPT_NAME="tool-name"
readonly SCRIPT_VERSION="1.0.0"
readonly LOCKFILE="/tmp/.${SCRIPT_NAME}.lock"
readonly LOGFILE="/var/log/userland-apps/${SCRIPT_NAME}.log"

# Logging functions
log_info() { echo "[$(date)] INFO: $*" | tee -a "$LOGFILE"; }
log_error() { echo "[$(date)] ERROR: $*" | tee -a "$LOGFILE" >&2; }

# Error handling
cleanup() { rm -f "$LOCKFILE"; }
trap cleanup EXIT

# Main functionality
main() {
    # Argument parsing
    # Lock acquisition  
    # Installation logic
    # Launch logic
}

main "$@"
```

## Application Metadata

### CSV Format

The `data/apps.csv` file contains metadata for all supported applications:

```csv
app_name,category,filesystem_type,supports_cli,supports_gui,is_paid_app,version,description
r-lang,math,debian,true,true,false,1,"R statistical computing language"
git-gui,development,debian,false,true,false,1,"Git GUI interface"
```

### Fields

- **app_name**: Unique identifier matching tool filename
- **category**: Application category (math, development, game, etc.)
- **filesystem_type**: Target filesystem/container type
- **supports_cli**: Whether app has CLI interface
- **supports_gui**: Whether app has GUI interface  
- **is_paid_app**: Whether app requires payment/license
- **version**: App definition version
- **description**: Human-readable description

## Asset Management

### Asset Categories

- **Cross-platform**: Scripts and utilities that work on any architecture
- **Architecture-specific**: Binaries compiled for specific CPU architectures
- **System utilities**: Helper scripts for container and system management

### Security

All assets are:
- Scanned for security vulnerabilities
- Verified with checksums  
- Sanitized and reviewed for safety
- Documented in the manifest

### Manifest Format

```csv
filename,architecture,size_bytes,sha256sum,purpose
addNonRootUser.sh,all,4045,abc123...,Creates non-root user accounts
```

## Testing

### Test Coverage

The test suite validates:

- **Syntax**: All scripts have valid bash syntax
- **Standards**: SPDX headers, error handling, argument parsing
- **Functionality**: Help/version options, error handling
- **Security**: Concurrent execution safety, input validation
- **Data**: CSV format validation, asset integrity

### Running Tests

```bash
# Full test suite
./tests/userland-apps/test-userland-apps.sh

# Individual tool testing
./tools/userland-apps/r-lang --help
NO_SUDO=1 ./tools/userland-apps/git-gui --install-only
```

### Test Environment Variables

- `NO_SUDO=1`: Skip privilege escalation for testing
- `USERLAND_APPS_LOG_LEVEL=ERROR`: Reduce log verbosity

## Integration

### Meson Build System

The userland-apps system integrates with the FileSystemds build system through `meson.build` configuration. Installation targets and test registration are handled automatically.

### Distribution Packaging

Tools follow distribution packaging guidelines:
- Standard filesystem hierarchy
- Proper file permissions
- Package dependencies
- Configuration files

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure scripts are executable (`chmod +x`)
2. **Sudo Issues**: Check sudo configuration and privileges
3. **Lock File Errors**: Remove stale locks from `/tmp/.*.lock`
4. **Log Permissions**: Ensure `/var/log/userland-apps/` is writable

### Debugging

Enable verbose logging:
```bash
export USERLAND_APPS_LOG_LEVEL=DEBUG
./tools/userland-apps/tool-name
```

Check log files:
```bash
tail -f /var/log/userland-apps/tool-name.log
```

### Support

For issues and development questions:
- Check log files in `/var/log/userland-apps/`
- Run test suite for validation
- Review this documentation
- Check FileSystemds project documentation

## Migration from UserlAsServer

This system replaces the original UserlAsServer with:

- **Improved Security**: Proper input validation, privilege handling
- **Better Reliability**: Error handling, logging, idempotent operations  
- **Modern Standards**: POSIX compliance, distribution packaging guidelines
- **Enhanced Testing**: Comprehensive test coverage
- **Production Ready**: Suitable for deployment in production environments

Original scripts like `r.sh`, `git.sh`, `zork.sh` have been completely rewritten as `r-lang`, `git-gui`, `zork` with modern implementations.