---
title: Build System Documentation
category: Platform Documentation
layout: default
SPDX-License-Identifier: LGPL-2.1-or-later
---

# MobileOps Build System Documentation

## Overview

The MobileOps build system provides a comprehensive, automated approach to building, packaging, and distributing platform components. It supports multiple target platforms, container images, mobile applications, and provides reproducible builds with dependency management and security scanning.

## Build System Architecture

### Core Components

1. **Build Controller**: Central orchestration of build processes
2. **Package Manager**: Handles component packaging and distribution
3. **Container Builder**: Creates and manages container images
4. **Mobile App Builder**: Builds Android and iOS applications
5. **Dependency Manager**: Manages build dependencies and versions
6. **Artifact Repository**: Stores and distributes build artifacts
7. **Security Scanner**: Scans builds for vulnerabilities
8. **Quality Assurance**: Automated testing and quality checks

### Build Targets

#### Platform Components
- Core platform scripts and utilities
- AI models and inference engines
- Network and security components
- Plugin system and extensions

#### Container Images
- Base runtime images
- Specialized service images
- Development and testing images
- Production deployment images

#### Mobile Applications
- Android APK packages
- iOS IPA packages
- Progressive Web Apps (PWA)
- Hybrid application packages

## Build Configuration

### Global Build Configuration

```yaml
# build-config.yaml
apiVersion: build.mobileops.io/v1
kind: BuildConfiguration
metadata:
  name: mobileops-build-config
spec:
  version: "1.0.0"
  buildEnvironment:
    baseImage: "ubuntu:22.04"
    architecture: ["amd64", "arm64"]
    timezone: "UTC"
    locale: "en_US.UTF-8"
  
  dependencies:
    system:
      - curl
      - git
      - build-essential
      - python3
      - python3-pip
      - nodejs
      - npm
    
    python:
      - requirements.txt
      - requirements-dev.txt
    
    node:
      - package.json
      - package-lock.json
  
  buildSteps:
    - name: setup-environment
      command: ./scripts/setup-build-env.sh
    - name: install-dependencies
      command: ./scripts/install-deps.sh
    - name: compile-components
      command: ./scripts/compile.sh
    - name: run-tests
      command: ./scripts/run-tests.sh
    - name: package-artifacts
      command: ./scripts/package.sh
    - name: security-scan
      command: ./scripts/security-scan.sh
  
  artifacts:
    - name: platform-scripts
      type: tarball
      path: "dist/scripts/"
      compression: gzip
    
    - name: container-images
      type: container
      registry: "ghcr.io/spiralgang"
      tags: ["latest", "${BUILD_VERSION}"]
    
    - name: mobile-apps
      type: mobile
      platforms: ["android", "ios"]
      signing: true
  
  quality:
    codeQuality:
      enabled: true
      threshold: 8.0
    
    testCoverage:
      enabled: true
      threshold: 80
    
    securityScan:
      enabled: true
      allowHighSeverity: false
    
    performanceTest:
      enabled: true
      maxResponseTime: 200ms
```

### Component-Specific Configuration

```yaml
# components/ai-core/build.yaml
apiVersion: build.mobileops.io/v1
kind: ComponentBuild
metadata:
  name: ai-core
spec:
  dependencies:
    - tensorflow>=2.12.0
    - torch>=2.0.0
    - numpy>=1.24.0
    - scikit-learn>=1.3.0
  
  buildSteps:
    - name: prepare-models
      command: python scripts/prepare-models.py
    - name: compile-inference-engine
      command: make -C inference/
    - name: package-models
      command: tar -czf ai-models.tar.gz models/
  
  tests:
    unit: tests/unit/test_ai_core.py
    integration: tests/integration/test_ai_integration.py
    performance: tests/performance/benchmark_inference.py
  
  artifacts:
    - name: ai-core-engine
      path: dist/ai-core/
      type: binary
    - name: ai-models
      path: ai-models.tar.gz
      type: data
```

## Build Execution

### Manual Build Process

```bash
# Initialize build environment
./scripts/build_release.sh init

# Prepare source code
./scripts/build_release.sh prepare

# Build all components
./scripts/build_release.sh build all

# Build specific component
./scripts/build_release.sh build ai-core

# Build container images
./scripts/build_release.sh images base

# Create release package
./scripts/build_release.sh release v1.0.0 "Initial release"

# Test the build
./scripts/build_release.sh test
```

### Automated Build Pipeline

```bash
#!/bin/bash
# scripts/ci-build.sh

set -euo pipefail

BUILD_ID="${BUILD_ID:-$(date +%Y%m%d%H%M%S)}"
BUILD_VERSION="${BUILD_VERSION:-1.0.0-$BUILD_ID}"
REGISTRY="${REGISTRY:-ghcr.io/spiralgang}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD: $*"
}

validate_environment() {
    log "Validating build environment"
    
    # Check required tools
    local required_tools=(docker git python3 node)
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null; then
            echo "ERROR: Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Check environment variables
    local required_vars=(BUILD_VERSION)
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "ERROR: Required environment variable not set: $var"
            exit 1
        fi
    done
}

setup_build_environment() {
    log "Setting up build environment"
    
    # Create build directories
    mkdir -p dist/{scripts,components,images,mobile}
    mkdir -p build-cache
    
    # Set build metadata
    cat > dist/build-info.json <<EOF
{
    "buildId": "$BUILD_ID",
    "version": "$BUILD_VERSION",
    "timestamp": "$(date -Iseconds)",
    "commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')"
}
EOF
}

build_platform_scripts() {
    log "Building platform scripts"
    
    # Copy and prepare scripts
    cp scripts/*.sh dist/scripts/
    chmod +x dist/scripts/*.sh
    
    # Validate script syntax
    for script in dist/scripts/*.sh; do
        if ! bash -n "$script"; then
            echo "ERROR: Syntax error in $script"
            exit 1
        fi
    done
    
    # Create scripts package
    tar -czf "dist/mobileops-scripts-$BUILD_VERSION.tar.gz" -C dist scripts/
    
    log "Platform scripts built successfully"
}

build_components() {
    log "Building platform components"
    
    # Build AI Core
    if [[ -f components/ai-core/build.sh ]]; then
        (cd components/ai-core && ./build.sh)
        cp -r components/ai-core/dist/* dist/components/
    fi
    
    # Build Network Components
    if [[ -f components/network/build.sh ]]; then
        (cd components/network && ./build.sh)
        cp -r components/network/dist/* dist/components/
    fi
    
    # Build Plugin System
    if [[ -f components/plugins/build.sh ]]; then
        (cd components/plugins && ./build.sh)
        cp -r components/plugins/dist/* dist/components/
    fi
    
    log "Components built successfully"
}

build_container_images() {
    log "Building container images"
    
    # Build base image
    docker build -t "$REGISTRY/mobileops-base:$BUILD_VERSION" \
        -f docker/Dockerfile.base .
    
    # Build AI image
    docker build -t "$REGISTRY/mobileops-ai:$BUILD_VERSION" \
        -f docker/Dockerfile.ai .
    
    # Build tools image
    docker build -t "$REGISTRY/mobileops-tools:$BUILD_VERSION" \
        -f docker/Dockerfile.tools .
    
    # Tag latest versions
    docker tag "$REGISTRY/mobileops-base:$BUILD_VERSION" \
        "$REGISTRY/mobileops-base:latest"
    
    log "Container images built successfully"
}

build_mobile_apps() {
    log "Building mobile applications"
    
    # Build Android app
    if [[ -d mobile/android ]]; then
        (cd mobile/android && ./gradlew assembleRelease)
        cp mobile/android/app/build/outputs/apk/release/*.apk dist/mobile/
    fi
    
    # Build iOS app (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d mobile/ios ]]; then
        (cd mobile/ios && xcodebuild -scheme MobileOps -configuration Release)
    fi
    
    log "Mobile applications built successfully"
}

run_quality_checks() {
    log "Running quality checks"
    
    # Code quality analysis
    if command -v sonar-scanner >/dev/null; then
        sonar-scanner -Dsonar.projectKey=mobileops \
            -Dsonar.sources=. \
            -Dsonar.host.url="$SONAR_HOST_URL" \
            -Dsonar.login="$SONAR_TOKEN"
    fi
    
    # Security scanning
    ./scripts/security-scan.sh
    
    # Test execution
    ./test_suite.sh all
    
    log "Quality checks completed"
}

package_release() {
    log "Packaging release"
    
    # Create release archive
    tar -czf "mobileops-$BUILD_VERSION.tar.gz" -C dist .
    
    # Generate checksums
    sha256sum "mobileops-$BUILD_VERSION.tar.gz" > "mobileops-$BUILD_VERSION.tar.gz.sha256"
    
    # Create release manifest
    cat > "mobileops-$BUILD_VERSION-manifest.json" <<EOF
{
    "version": "$BUILD_VERSION",
    "buildId": "$BUILD_ID",
    "timestamp": "$(date -Iseconds)",
    "components": {
        "scripts": "mobileops-scripts-$BUILD_VERSION.tar.gz",
        "platform": "mobileops-$BUILD_VERSION.tar.gz"
    },
    "containers": [
        "$REGISTRY/mobileops-base:$BUILD_VERSION",
        "$REGISTRY/mobileops-ai:$BUILD_VERSION",
        "$REGISTRY/mobileops-tools:$BUILD_VERSION"
    ],
    "checksums": {
        "sha256": "$(cat mobileops-$BUILD_VERSION.tar.gz.sha256 | cut -d' ' -f1)"
    }
}
EOF
    
    log "Release packaged successfully"
}

publish_artifacts() {
    log "Publishing artifacts"
    
    # Push container images
    if [[ "${PUSH_IMAGES:-false}" == "true" ]]; then
        docker push "$REGISTRY/mobileops-base:$BUILD_VERSION"
        docker push "$REGISTRY/mobileops-ai:$BUILD_VERSION"
        docker push "$REGISTRY/mobileops-tools:$BUILD_VERSION"
        docker push "$REGISTRY/mobileops-base:latest"
    fi
    
    # Upload to artifact repository
    if [[ -n "${ARTIFACT_REPO_URL:-}" ]]; then
        curl -X POST \
            -H "Authorization: Bearer $ARTIFACT_REPO_TOKEN" \
            -F "file=@mobileops-$BUILD_VERSION.tar.gz" \
            "$ARTIFACT_REPO_URL/upload"
    fi
    
    log "Artifacts published successfully"
}

cleanup_build() {
    log "Cleaning up build environment"
    
    # Remove temporary files
    rm -rf build-cache/temp/*
    
    # Clean Docker images (keep recent ones)
    docker image prune -f
    
    log "Build cleanup completed"
}

main() {
    log "Starting build process (Build ID: $BUILD_ID, Version: $BUILD_VERSION)"
    
    # Set up error handling
    trap cleanup_build EXIT
    
    # Execute build pipeline
    validate_environment
    setup_build_environment
    build_platform_scripts
    build_components
    build_container_images
    build_mobile_apps
    run_quality_checks
    package_release
    publish_artifacts
    
    log "Build process completed successfully"
    echo "Build artifacts:"
    echo "  Release package: mobileops-$BUILD_VERSION.tar.gz"
    echo "  Container images: $REGISTRY/mobileops-*:$BUILD_VERSION"
    echo "  Build manifest: mobileops-$BUILD_VERSION-manifest.json"
}

main "$@"
```

## Docker and Container Builds

### Base Container Image

```dockerfile
# docker/Dockerfile.base
FROM ubuntu:22.04

LABEL maintainer="MobileOps Team"
LABEL version="1.0.0"
LABEL description="MobileOps Platform Base Image"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV MOBILEOPS_HOME=/opt/mobileops

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create mobileops user
RUN useradd -m -u 1000 mobileops && \
    mkdir -p $MOBILEOPS_HOME && \
    chown -R mobileops:mobileops $MOBILEOPS_HOME

# Install Python dependencies
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Copy platform scripts
COPY scripts/ $MOBILEOPS_HOME/scripts/
RUN chmod +x $MOBILEOPS_HOME/scripts/*.sh

# Copy configuration templates
COPY configs/ $MOBILEOPS_HOME/configs/

# Set working directory
WORKDIR $MOBILEOPS_HOME
USER mobileops

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["./scripts/platform_launcher.sh", "start"]
```

### AI-Specific Container

```dockerfile
# docker/Dockerfile.ai
FROM mobileops-base:latest

# Install AI/ML dependencies
USER root
RUN pip3 install --no-cache-dir \
    tensorflow>=2.12.0 \
    torch>=2.0.0 \
    transformers>=4.30.0 \
    scikit-learn>=1.3.0 \
    opencv-python>=4.8.0

# Install CUDA support (if available)
RUN if command -v nvidia-smi >/dev/null; then \
        pip3 install --no-cache-dir \
        tensorflow-gpu \
        torch-audio \
        torchvision; \
    fi

# Copy AI models and components
COPY components/ai-core/ $MOBILEOPS_HOME/ai-core/
COPY models/ $MOBILEOPS_HOME/models/

# Set AI-specific environment variables
ENV PYTHONPATH=$MOBILEOPS_HOME/ai-core:$PYTHONPATH
ENV CUDA_VISIBLE_DEVICES=0

USER mobileops

# AI service port
EXPOSE 8081

CMD ["./scripts/ai_core_manager.sh", "start"]
```

### Multi-Stage Build Example

```dockerfile
# docker/Dockerfile.optimized
# Build stage
FROM node:18-alpine AS builder

WORKDIR /build
COPY mobile/webapp/package*.json ./
RUN npm ci --only=production

COPY mobile/webapp/ ./
RUN npm run build

# Runtime stage
FROM mobileops-base:latest

# Copy built assets
COPY --from=builder /build/dist/ $MOBILEOPS_HOME/webapp/

# Configure web server
COPY configs/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```

## Mobile Application Builds

### Android Build Configuration

```gradle
// mobile/android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.mobileops.platform"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode getVersionCode()
        versionName getVersionName()
        
        buildConfigField "String", "BUILD_TIME", "\"${buildTime}\""
        buildConfigField "String", "GIT_COMMIT", "\"${gitCommit}\""
    }
    
    signingConfigs {
        release {
            storeFile file("../keystore/mobileops-release.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias "mobileops-release"
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        debug {
            debuggable true
            minifyEnabled false
            applicationIdSuffix ".debug"
        }
        
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
    
    productFlavors {
        dev {
            buildConfigField "String", "API_BASE_URL", "\"https://dev-api.mobileops.local\""
        }
        
        prod {
            buildConfigField "String", "API_BASE_URL", "\"https://api.mobileops.local\""
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.11.0'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}

def getVersionCode() {
    return System.getenv("BUILD_NUMBER")?.toInteger() ?: 1
}

def getVersionName() {
    return System.getenv("BUILD_VERSION") ?: "1.0.0-dev"
}

def getBuildTime() {
    return new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone("UTC"))
}

def getGitCommit() {
    return System.getenv("GIT_COMMIT") ?: "unknown"
}
```

### iOS Build Configuration

```ruby
# mobile/ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  before_all do
    setup_circle_ci
  end
  
  desc "Build and test the app"
  lane :test do
    scan(
      project: "MobileOps.xcodeproj",
      scheme: "MobileOps",
      device: "iPhone 14",
      clean: true
    )
  end
  
  desc "Build release version"
  lane :build_release do
    increment_build_number(
      build_number: ENV["BUILD_NUMBER"] || "1"
    )
    
    increment_version_number(
      version_number: ENV["BUILD_VERSION"] || "1.0.0"
    )
    
    build_app(
      project: "MobileOps.xcodeproj",
      scheme: "MobileOps",
      configuration: "Release",
      export_method: "app-store"
    )
  end
  
  desc "Deploy to TestFlight"
  lane :deploy_testflight do
    build_release
    
    upload_to_testflight(
      api_key_path: "fastlane/AuthKey.p8",
      skip_waiting_for_build_processing: true
    )
  end
  
  desc "Deploy to App Store"
  lane :deploy_appstore do
    build_release
    
    upload_to_app_store(
      api_key_path: "fastlane/AuthKey.p8",
      submit_for_review: false,
      automatic_release: false
    )
  end
end
```

## Dependency Management

### Python Dependencies

```txt
# requirements.txt
# Core dependencies
flask==2.3.2
requests==2.31.0
pyyaml==6.0
psutil==5.9.5
cryptography==41.0.1

# AI/ML dependencies
tensorflow==2.12.0
torch==2.0.1
numpy==1.24.3
scikit-learn==1.3.0
transformers==4.30.2

# Development dependencies
pytest==7.4.0
black==23.3.0
flake8==6.0.0
mypy==1.4.1
coverage==7.2.7
```

```txt
# requirements-dev.txt
# Development and testing tools
pytest==7.4.0
pytest-cov==4.1.0
pytest-mock==3.11.1
black==23.3.0
flake8==6.0.0
mypy==1.4.1
bandit==1.7.5
safety==2.3.4

# Documentation
sphinx==7.1.1
sphinx-rtd-theme==1.2.2
mkdocs==1.4.3
mkdocs-material==9.1.15
```

### Node.js Dependencies

```json
{
  "name": "mobileops-webapp",
  "version": "1.0.0",
  "description": "MobileOps Web Application",
  "scripts": {
    "build": "webpack --mode production",
    "dev": "webpack serve --mode development",
    "test": "jest",
    "lint": "eslint src/",
    "format": "prettier --write src/"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.4.0",
    "react-router-dom": "^6.14.1",
    "@mui/material": "^5.13.6"
  },
  "devDependencies": {
    "webpack": "^5.88.1",
    "webpack-cli": "^5.1.4",
    "webpack-dev-server": "^4.15.1",
    "@babel/core": "^7.22.5",
    "@babel/preset-react": "^7.22.5",
    "babel-loader": "^9.1.2",
    "jest": "^29.5.0",
    "@testing-library/react": "^13.4.0",
    "eslint": "^8.44.0",
    "eslint-plugin-react": "^7.32.2",
    "prettier": "^3.0.0"
  }
}
```

## Build Optimization

### Parallel Builds

```bash
#!/bin/bash
# scripts/parallel-build.sh

build_component() {
    local component="$1"
    echo "Building $component..."
    
    case "$component" in
        "scripts")
            ./scripts/build_release.sh build scripts
            ;;
        "ai-core")
            (cd components/ai-core && make build)
            ;;
        "network")
            (cd components/network && ./build.sh)
            ;;
        "plugins")
            (cd components/plugins && npm run build)
            ;;
    esac
    
    echo "Completed $component"
}

# Build components in parallel
components=("scripts" "ai-core" "network" "plugins")

for component in "${components[@]}"; do
    build_component "$component" &
done

# Wait for all builds to complete
wait

echo "All components built successfully"
```

### Build Caching

```bash
# scripts/cache-build.sh

setup_build_cache() {
    local cache_dir="/var/cache/mobileops-build"
    mkdir -p "$cache_dir"/{dependencies,artifacts,docker}
    
    # Enable Docker layer caching
    export DOCKER_BUILDKIT=1
    export BUILDKIT_PROGRESS=plain
    
    # Cache Python packages
    export PIP_CACHE_DIR="$cache_dir/dependencies/pip"
    
    # Cache npm packages
    export NPM_CONFIG_CACHE="$cache_dir/dependencies/npm"
}

cache_artifacts() {
    local build_version="$1"
    local cache_key="$(sha256sum requirements.txt package.json | sha256sum | cut -d' ' -f1)"
    local cache_file="/var/cache/mobileops-build/artifacts/$cache_key.tar.gz"
    
    if [[ -f "$cache_file" ]]; then
        echo "Restoring from cache: $cache_key"
        tar -xzf "$cache_file" -C .
        return 0
    fi
    
    return 1
}

save_to_cache() {
    local cache_key="$1"
    local cache_file="/var/cache/mobileops-build/artifacts/$cache_key.tar.gz"
    
    echo "Saving to cache: $cache_key"
    tar -czf "$cache_file" dist/
}
```

## Security in Builds

### Secure Build Environment

```bash
# scripts/secure-build.sh

setup_secure_environment() {
    # Verify build environment integrity
    if ! ./scripts/toolbox_integrity_check.sh verify; then
        echo "ERROR: Build environment integrity check failed"
        exit 1
    fi
    
    # Scan dependencies for vulnerabilities
    ./scripts/security-scan-deps.sh
    
    # Set up secure temporary directories
    export TMPDIR="/secure/tmp"
    mkdir -p "$TMPDIR"
    chmod 700 "$TMPDIR"
}

sign_artifacts() {
    local artifact="$1"
    local signing_key="${SIGNING_KEY:-/etc/ssl/private/mobileops-signing.key}"
    
    if [[ -f "$signing_key" ]]; then
        echo "Signing artifact: $artifact"
        gpg --armor --detach-sign --default-key mobileops@example.com "$artifact"
    else
        echo "WARNING: Signing key not found, skipping artifact signing"
    fi
}

verify_signatures() {
    local artifact="$1"
    
    if [[ -f "$artifact.asc" ]]; then
        gpg --verify "$artifact.asc" "$artifact"
    else
        echo "WARNING: No signature found for $artifact"
    fi
}
```

### Supply Chain Security

```yaml
# .github/workflows/security.yml
name: Supply Chain Security

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Scan Python dependencies
      run: |
        pip install safety
        safety check -r requirements.txt
    
    - name: Scan Node.js dependencies
      run: |
        npm audit --audit-level moderate
    
    - name: SBOM Generation
      uses: anchore/sbom-action@v0
      with:
        path: ./
        format: spdx-json
    
    - name: Container Security Scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
```

## Build Monitoring and Metrics

### Build Metrics Collection

```python
#!/usr/bin/env python3
# scripts/build-metrics.py

import time
import json
import psutil
import requests
from datetime import datetime

class BuildMetrics:
    def __init__(self):
        self.start_time = time.time()
        self.metrics = {
            'build_id': os.environ.get('BUILD_ID', 'unknown'),
            'start_time': datetime.utcnow().isoformat(),
            'components': {},
            'resources': {},
            'artifacts': {}
        }
    
    def start_component(self, component_name):
        self.metrics['components'][component_name] = {
            'start_time': time.time(),
            'status': 'building'
        }
    
    def complete_component(self, component_name, success=True):
        if component_name in self.metrics['components']:
            component = self.metrics['components'][component_name]
            component['end_time'] = time.time()
            component['duration'] = component['end_time'] - component['start_time']
            component['status'] = 'success' if success else 'failed'
    
    def record_resource_usage(self):
        self.metrics['resources'] = {
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'timestamp': time.time()
        }
    
    def record_artifact(self, name, size, checksum):
        self.metrics['artifacts'][name] = {
            'size': size,
            'checksum': checksum,
            'created_at': time.time()
        }
    
    def finalize(self, success=True):
        self.metrics['end_time'] = datetime.utcnow().isoformat()
        self.metrics['total_duration'] = time.time() - self.start_time
        self.metrics['status'] = 'success' if success else 'failed'
        
        # Save metrics
        with open('build-metrics.json', 'w') as f:
            json.dump(self.metrics, f, indent=2)
        
        # Send to monitoring system
        self.send_metrics()
    
    def send_metrics(self):
        metrics_url = os.environ.get('METRICS_URL')
        if metrics_url:
            try:
                requests.post(metrics_url, json=self.metrics, timeout=10)
            except Exception as e:
                print(f"Failed to send metrics: {e}")

if __name__ == "__main__":
    import os
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: build-metrics.py <start|complete|resource|artifact|finalize>")
        sys.exit(1)
    
    action = sys.argv[1]
    metrics = BuildMetrics()
    
    # Load existing metrics if available
    if os.path.exists('build-metrics.json'):
        with open('build-metrics.json', 'r') as f:
            metrics.metrics = json.load(f)
    
    if action == "start" and len(sys.argv) > 2:
        metrics.start_component(sys.argv[2])
    elif action == "complete" and len(sys.argv) > 2:
        success = sys.argv[3].lower() == "true" if len(sys.argv) > 3 else True
        metrics.complete_component(sys.argv[2], success)
    elif action == "resource":
        metrics.record_resource_usage()
    elif action == "artifact" and len(sys.argv) > 4:
        metrics.record_artifact(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    elif action == "finalize":
        success = sys.argv[2].lower() == "true" if len(sys.argv) > 2 else True
        metrics.finalize(success)
    
    # Save updated metrics
    with open('build-metrics.json', 'w') as f:
        json.dump(metrics.metrics, f, indent=2)
```

## Troubleshooting Builds

### Common Build Issues

```bash
#!/bin/bash
# scripts/build-troubleshoot.sh

diagnose_build_failure() {
    echo "=== BUILD FAILURE DIAGNOSIS ==="
    
    # Check disk space
    echo "Disk Space:"
    df -h
    
    # Check memory usage
    echo -e "\nMemory Usage:"
    free -h
    
    # Check recent build logs
    echo -e "\nRecent Build Logs:"
    tail -50 /var/log/mobileops/build_release.log
    
    # Check for common issues
    check_dependency_conflicts
    check_permission_issues
    check_network_connectivity
}

check_dependency_conflicts() {
    echo -e "\n=== DEPENDENCY ANALYSIS ==="
    
    # Python dependency conflicts
    if command -v pip >/dev/null; then
        pip check || echo "Python dependency conflicts detected"
    fi
    
    # Node.js dependency conflicts
    if [[ -f package.json ]] && command -v npm >/dev/null; then
        npm ls --depth=0 || echo "Node.js dependency conflicts detected"
    fi
}

check_permission_issues() {
    echo -e "\n=== PERMISSION ANALYSIS ==="
    
    # Check build directory permissions
    ls -la dist/ || echo "Build directory not accessible"
    
    # Check script permissions
    find scripts/ -name "*.sh" ! -perm -u+x -ls || echo "All scripts are executable"
}

check_network_connectivity() {
    echo -e "\n=== NETWORK CONNECTIVITY ==="
    
    # Test internet connectivity
    curl -s --connect-timeout 5 https://google.com >/dev/null && \
        echo "Internet connectivity: OK" || \
        echo "Internet connectivity: FAILED"
    
    # Test package repositories
    pip install --dry-run requests >/dev/null 2>&1 && \
        echo "PyPI connectivity: OK" || \
        echo "PyPI connectivity: FAILED"
}

# Run diagnosis if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    diagnose_build_failure
fi
```

## Best Practices

1. **Reproducible Builds**: Use fixed dependency versions and build environments
2. **Security First**: Scan dependencies and artifacts for vulnerabilities
3. **Parallel Processing**: Build components in parallel to reduce build time
4. **Caching Strategy**: Implement effective caching for dependencies and artifacts
5. **Quality Gates**: Enforce quality checks before artifact creation
6. **Monitoring**: Track build metrics and performance
7. **Documentation**: Maintain up-to-date build documentation
8. **Version Management**: Use semantic versioning and proper tagging

## Support and Resources

- **Build System Documentation**: [https://docs.mobileops.local/build-system](https://docs.mobileops.local/build-system)
- **CI/CD Pipeline**: [https://ci.mobileops.local](https://ci.mobileops.local)
- **Artifact Repository**: [https://artifacts.mobileops.local](https://artifacts.mobileops.local)
- **Build Metrics Dashboard**: [https://metrics.mobileops.local/builds](https://metrics.mobileops.local/builds)
- **Container Registry**: [https://registry.mobileops.local](https://registry.mobileops.local)