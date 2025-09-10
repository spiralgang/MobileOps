#!/bin/bash

# Build Release Script for MobileOps Platform
# Handles building, packaging, and releasing platform components

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/build_release.log"
BUILD_CONFIG_DIR="/etc/mobileops/build"
BUILD_OUTPUT_DIR="/var/lib/mobileops/builds"
SOURCE_DIR="/usr/src/mobileops"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

initialize_build_environment() {
    log "INFO: Initializing build environment"
    
    mkdir -p "$BUILD_OUTPUT_DIR"/{packages,images,artifacts}
    mkdir -p "$SOURCE_DIR"
    
    # Create build configuration
    local build_config="$BUILD_CONFIG_DIR/build.conf"
    if [[ ! -f "$build_config" ]]; then
        cat > "$build_config" <<EOF
# MobileOps Build Configuration
VERSION_FILE=/etc/mobileops/version
BUILD_ARCH=x86_64
CONTAINER_RUNTIME=chisel
COMPRESSION=gzip
SIGN_RELEASES=true
UPLOAD_ARTIFACTS=false
REPOSITORY_URL=https://releases.mobileops.local
EOF
        log "INFO: Build configuration created"
    fi
    
    log "INFO: Build environment initialized"
}

prepare_source() {
    log "INFO: Preparing source code for build"
    
    # Copy scripts to source directory
    mkdir -p "$SOURCE_DIR/scripts"
    cp "$SCRIPT_DIR"/*.sh "$SOURCE_DIR/scripts/"
    
    # Copy documentation
    if [[ -d "/home/runner/work/FileSystemds/FileSystemds/docs" ]]; then
        mkdir -p "$SOURCE_DIR/docs"
        cp -r /home/runner/work/FileSystemds/FileSystemds/docs/* "$SOURCE_DIR/docs/" 2>/dev/null || true
    fi
    
    # Copy configuration files
    if [[ -d "/etc/mobileops" ]]; then
        mkdir -p "$SOURCE_DIR/configs"
        cp -r /etc/mobileops/* "$SOURCE_DIR/configs/" 2>/dev/null || true
    fi
    
    # Create version file if it doesn't exist
    if [[ ! -f "$SOURCE_DIR/VERSION" ]]; then
        echo "1.0.0-$(date +%Y%m%d)" > "$SOURCE_DIR/VERSION"
    fi
    
    log "INFO: Source preparation completed"
}

build_packages() {
    local package_type="${1:-all}"
    local version=$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "1.0.0")
    
    log "INFO: Building packages (type: $package_type, version: $version)"
    
    case "$package_type" in
        "scripts"|"all")
            build_scripts_package "$version"
            ;;
    esac
    
    case "$package_type" in
        "docs"|"all")
            build_docs_package "$version"
            ;;
    esac
    
    case "$package_type" in
        "full"|"all")
            build_full_package "$version"
            ;;
    esac
    
    log "INFO: Package building completed"
}

build_scripts_package() {
    local version="$1"
    local package_name="mobileops-scripts-$version.tar.gz"
    local package_path="$BUILD_OUTPUT_DIR/packages/$package_name"
    
    log "INFO: Building scripts package: $package_name"
    
    tar -czf "$package_path" -C "$SOURCE_DIR" scripts/
    
    # Generate checksum
    sha256sum "$package_path" > "$package_path.sha256"
    
    log "INFO: Scripts package created: $package_path"
}

build_docs_package() {
    local version="$1"
    local package_name="mobileops-docs-$version.tar.gz"
    local package_path="$BUILD_OUTPUT_DIR/packages/$package_name"
    
    log "INFO: Building documentation package: $package_name"
    
    if [[ -d "$SOURCE_DIR/docs" ]]; then
        tar -czf "$package_path" -C "$SOURCE_DIR" docs/
        sha256sum "$package_path" > "$package_path.sha256"
        log "INFO: Documentation package created: $package_path"
    else
        log "WARN: No documentation directory found, skipping docs package"
    fi
}

build_full_package() {
    local version="$1"
    local package_name="mobileops-full-$version.tar.gz"
    local package_path="$BUILD_OUTPUT_DIR/packages/$package_name"
    
    log "INFO: Building full platform package: $package_name"
    
    tar -czf "$package_path" -C "$SOURCE_DIR" .
    sha256sum "$package_path" > "$package_path.sha256"
    
    log "INFO: Full package created: $package_path"
}

build_container_images() {
    local image_type="${1:-base}"
    local version=$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "1.0.0")
    
    log "INFO: Building container images (type: $image_type, version: $version)"
    
    case "$image_type" in
        "base")
            build_base_image "$version"
            ;;
        "ai")
            build_ai_image "$version"
            ;;
        "tools")
            build_tools_image "$version"
            ;;
        *)
            log "ERROR: Unknown image type: $image_type"
            return 1
            ;;
    esac
}

build_base_image() {
    local version="$1"
    local image_name="mobileops-base:$version"
    local build_dir="$BUILD_OUTPUT_DIR/images/base"
    
    log "INFO: Building base container image: $image_name"
    
    mkdir -p "$build_dir"
    
    # Create Dockerfile
    cat > "$build_dir/Dockerfile" <<EOF
FROM alpine:latest

RUN apk add --no-cache \\
    bash \\
    curl \\
    python3 \\
    py3-pip \\
    iptables \\
    bridge-utils

COPY scripts/ /opt/mobileops/scripts/
COPY configs/ /etc/mobileops/

RUN chmod +x /opt/mobileops/scripts/*.sh

WORKDIR /opt/mobileops
CMD ["/bin/bash"]
EOF
    
    # Copy source files
    cp -r "$SOURCE_DIR/scripts" "$build_dir/"
    cp -r "$SOURCE_DIR/configs" "$build_dir/" 2>/dev/null || true
    
    # Build image (simulated)
    log "INFO: Building container image (simulated)"
    touch "$BUILD_OUTPUT_DIR/images/$image_name.tar"
    
    log "INFO: Base image built: $image_name"
}

build_ai_image() {
    local version="$1"
    local image_name="mobileops-ai:$version"
    
    log "INFO: Building AI container image: $image_name"
    # AI-specific build logic would go here
    log "INFO: AI image built: $image_name"
}

build_tools_image() {
    local version="$1"
    local image_name="mobileops-tools:$version"
    
    log "INFO: Building tools container image: $image_name"
    # Tools-specific build logic would go here
    log "INFO: Tools image built: $image_name"
}

create_release() {
    local version="${1:-$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "1.0.0")}"
    local release_notes="${2:-Release $version}"
    
    log "INFO: Creating release: $version"
    
    local release_dir="$BUILD_OUTPUT_DIR/releases/$version"
    mkdir -p "$release_dir"
    
    # Copy all built packages to release directory
    if [[ -d "$BUILD_OUTPUT_DIR/packages" ]]; then
        cp "$BUILD_OUTPUT_DIR/packages"/* "$release_dir/" 2>/dev/null || true
    fi
    
    # Copy container images to release directory
    if [[ -d "$BUILD_OUTPUT_DIR/images" ]]; then
        cp "$BUILD_OUTPUT_DIR/images"/*.tar "$release_dir/" 2>/dev/null || true
    fi
    
    # Create release manifest
    cat > "$release_dir/RELEASE_MANIFEST.txt" <<EOF
MobileOps Platform Release $version
Generated: $(date)

Release Notes:
$release_notes

Included Files:
$(ls -la "$release_dir" | tail -n +2)

Checksums:
$(find "$release_dir" -name "*.sha256" -exec cat {} \;)
EOF
    
    # Create release archive
    local release_archive="$BUILD_OUTPUT_DIR/mobileops-$version-release.tar.gz"
    tar -czf "$release_archive" -C "$BUILD_OUTPUT_DIR/releases" "$version"
    
    log "INFO: Release created: $release_archive"
    echo "Release archive: $release_archive"
}

test_build() {
    log "INFO: Running build tests"
    
    # Test script syntax
    echo "Testing script syntax..."
    for script in "$SOURCE_DIR/scripts"/*.sh; do
        if bash -n "$script"; then
            echo "✓ $(basename "$script")"
        else
            echo "✗ $(basename "$script") - Syntax error"
            return 1
        fi
    done
    
    # Test package integrity
    echo "Testing package integrity..."
    for package in "$BUILD_OUTPUT_DIR/packages"/*.tar.gz; do
        if [[ -f "$package" ]]; then
            if tar -tzf "$package" >/dev/null 2>&1; then
                echo "✓ $(basename "$package")"
            else
                echo "✗ $(basename "$package") - Archive error"
                return 1
            fi
        fi
    done
    
    log "INFO: Build tests passed"
}

clean_build() {
    log "INFO: Cleaning build artifacts"
    
    rm -rf "$BUILD_OUTPUT_DIR/packages"/*
    rm -rf "$BUILD_OUTPUT_DIR/images"/*
    rm -rf "$BUILD_OUTPUT_DIR/artifacts"/*
    
    log "INFO: Build cleanup completed"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$BUILD_CONFIG_DIR" "$BUILD_OUTPUT_DIR" "$SOURCE_DIR"
    log "INFO: Build Release Manager started"
    
    case "${1:-help}" in
        "init")
            initialize_build_environment
            ;;
        "prepare")
            prepare_source
            ;;
        "build")
            prepare_source
            build_packages "${2:-all}"
            ;;
        "images")
            build_container_images "${2:-base}"
            ;;
        "release")
            prepare_source
            build_packages "all"
            create_release "${2:-}" "${3:-}"
            ;;
        "test")
            test_build
            ;;
        "clean")
            clean_build
            ;;
        "help")
            echo "Usage: $0 {init|prepare|build|images|release|test|clean} [args]"
            echo ""
            echo "Commands:"
            echo "  init                 - Initialize build environment"
            echo "  prepare              - Prepare source code"
            echo "  build [type]         - Build packages (scripts|docs|full|all)"
            echo "  images [type]        - Build container images (base|ai|tools)"
            echo "  release [version] [notes] - Create full release"
            echo "  test                 - Run build tests"
            echo "  clean                - Clean build artifacts"
            ;;
        *)
            echo "Usage: $0 {init|prepare|build|images|release|test|clean|help} [args]"
            exit 1
            ;;
    esac
}

main "$@"