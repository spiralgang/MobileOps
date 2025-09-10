---
title: Testing and Continuous Integration
category: Platform Documentation
layout: default
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Testing and Continuous Integration Documentation

## Overview

The MobileOps platform implements a comprehensive testing and continuous integration framework designed to ensure code quality, reliability, and automated deployment across all platform components. This document outlines the testing strategies, CI/CD pipelines, and quality assurance processes.

## Testing Strategy

### Testing Pyramid

1. **Unit Tests (70%)**: Fast, isolated tests for individual functions and components
2. **Integration Tests (20%)**: Tests for component interactions and API contracts
3. **End-to-End Tests (10%)**: Full system tests simulating real user scenarios

### Test Categories

#### Functional Testing
- Unit tests for individual scripts and functions
- Integration tests for component communication
- API contract tests
- User acceptance tests

#### Non-Functional Testing
- Performance and load testing
- Security vulnerability testing
- Reliability and stress testing
- Compatibility testing across platforms

#### Specialized Testing
- Mobile device testing on real devices
- AI model accuracy and performance testing
- Container and VM functionality testing
- Network connectivity and security testing

## Test Framework Architecture

### Core Testing Components

```bash
# Test suite architecture
tests/
├── unit/                    # Unit tests
│   ├── scripts/            # Script unit tests
│   ├── components/         # Component unit tests
│   └── utils/              # Utility function tests
├── integration/            # Integration tests
│   ├── api/               # API integration tests
│   ├── components/        # Component integration
│   └── end-to-end/        # E2E test scenarios
├── performance/           # Performance tests
│   ├── load/              # Load testing
│   ├── stress/            # Stress testing
│   └── benchmarks/        # Performance benchmarks
├── security/              # Security tests
│   ├── vulnerability/     # Vulnerability scans
│   ├── penetration/       # Penetration tests
│   └── compliance/        # Compliance tests
└── fixtures/              # Test data and fixtures
    ├── data/              # Test data files
    ├── configs/           # Test configurations
    └── mocks/             # Mock services
```

### Test Execution Framework

```bash
# Master test runner
./test_suite.sh all

# Individual test categories
./test_suite.sh unit
./test_suite.sh integration
./test_suite.sh performance
./test_suite.sh security

# Specific test suites
./test_suite.sh unit scripts
./test_suite.sh integration api
./test_suite.sh performance load
```

## Unit Testing

### Script Unit Testing

```bash
#!/bin/bash
# tests/unit/scripts/test_platform_launcher.sh

source "$(dirname "$0")/../../lib/test_framework.sh"
source "$(dirname "$0")/../../../scripts/platform_launcher.sh"

test_platform_initialization() {
    describe "Platform initialization"
    
    # Setup test environment
    setup_test_environment
    
    # Test platform initialization
    result=$(initialize_platform 2>&1)
    exit_code=$?
    
    # Assertions
    assert_equals 0 $exit_code "Platform initialization should succeed"
    assert_contains "$result" "Platform initialized" "Should confirm initialization"
    
    # Cleanup
    cleanup_test_environment
}

test_service_management() {
    describe "Service start/stop functionality"
    
    # Mock external dependencies
    mock_service_command() {
        echo "Service operation successful"
        return 0
    }
    
    # Test service start
    result=$(start_platform 2>&1)
    assert_equals 0 $? "Service start should succeed"
    
    # Test service stop
    result=$(stop_platform 2>&1)
    assert_equals 0 $? "Service stop should succeed"
}

run_tests() {
    test_platform_initialization
    test_service_management
    
    # Report results
    report_test_results
}

run_tests
```

### Component Unit Testing

```python
#!/usr/bin/env python3
# tests/unit/components/test_ai_core.py

import unittest
import sys
import os

# Add project path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../'))

from components.ai_core import AIManager
from tests.lib.mocks import MockModel, MockResourceManager

class TestAICore(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures"""
        self.ai_manager = AIManager(test_mode=True)
        self.mock_model = MockModel()
        self.mock_resources = MockResourceManager()
    
    def test_model_loading(self):
        """Test AI model loading functionality"""
        # Test successful model loading
        result = self.ai_manager.load_model("test-model")
        self.assertTrue(result.success)
        self.assertEqual(result.model_name, "test-model")
        
        # Test invalid model loading
        with self.assertRaises(ModelNotFoundError):
            self.ai_manager.load_model("non-existent-model")
    
    def test_inference_execution(self):
        """Test AI inference execution"""
        # Load test model
        self.ai_manager.load_model("sentiment-analysis")
        
        # Test inference
        result = self.ai_manager.inference(
            model="sentiment-analysis",
            input_data="This is a positive test message"
        )
        
        self.assertIsNotNone(result)
        self.assertIn("sentiment", result)
        self.assertIn("confidence", result)
    
    def test_resource_management(self):
        """Test resource allocation and management"""
        initial_memory = self.ai_manager.get_memory_usage()
        
        # Load multiple models
        for i in range(3):
            self.ai_manager.load_model(f"test-model-{i}")
        
        # Check resource usage increased
        current_memory = self.ai_manager.get_memory_usage()
        self.assertGreater(current_memory, initial_memory)
        
        # Cleanup models
        self.ai_manager.cleanup_models()
        
        # Check resource usage decreased
        final_memory = self.ai_manager.get_memory_usage()
        self.assertLess(final_memory, current_memory)

if __name__ == '__main__':
    unittest.main()
```

## Integration Testing

### API Integration Testing

```python
#!/usr/bin/env python3
# tests/integration/api/test_platform_api.py

import requests
import unittest
import time
from tests.lib.test_server import TestServer

class TestPlatformAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Start test server"""
        cls.test_server = TestServer()
        cls.test_server.start()
        cls.base_url = cls.test_server.get_url()
        
        # Wait for server to be ready
        time.sleep(2)
    
    @classmethod
    def tearDownClass(cls):
        """Stop test server"""
        cls.test_server.stop()
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = requests.get(f"{self.base_url}/health")
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
    
    def test_ai_inference_api(self):
        """Test AI inference API endpoint"""
        payload = {
            "model": "sentiment-analysis",
            "input": "This is a test message",
            "parameters": {
                "confidence_threshold": 0.8
            }
        }
        
        response = requests.post(
            f"{self.base_url}/api/v1/ai/inference",
            json=payload
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("result", data)
        self.assertIn("confidence", data)
    
    def test_component_management_api(self):
        """Test component management endpoints"""
        # List components
        response = requests.get(f"{self.base_url}/api/v1/components")
        self.assertEqual(response.status_code, 200)
        
        # Start component
        response = requests.post(
            f"{self.base_url}/api/v1/components/ai-core/start"
        )
        self.assertEqual(response.status_code, 200)
        
        # Check component status
        response = requests.get(
            f"{self.base_url}/api/v1/components/ai-core/status"
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "running")
```

### Component Integration Testing

```bash
#!/bin/bash
# tests/integration/components/test_platform_integration.sh

source "$(dirname "$0")/../../lib/test_framework.sh"

test_full_platform_startup() {
    describe "Full platform startup integration"
    
    # Start platform
    ./scripts/platform_launcher.sh init
    assert_equals 0 $? "Platform initialization should succeed"
    
    ./scripts/platform_launcher.sh start
    assert_equals 0 $? "Platform startup should succeed"
    
    # Verify components are running
    ./scripts/ai_core_manager.sh status
    assert_equals 0 $? "AI Core should be running"
    
    ./scripts/network_configure.sh monitor
    assert_equals 0 $? "Network should be configured"
    
    # Test component communication
    test_component_communication
    
    # Cleanup
    ./scripts/platform_launcher.sh stop
}

test_component_communication() {
    describe "Inter-component communication"
    
    # Test AI Core and Plugin Manager communication
    ./scripts/plugin_manager.sh install test-ai-plugin
    assert_equals 0 $? "Plugin installation should succeed"
    
    ./scripts/ai_core_manager.sh load test-model
    assert_equals 0 $? "Model loading should succeed"
    
    # Test API communication
    response=$(curl -s http://localhost:8080/api/v1/ai/models)
    assert_contains "$response" "test-model" "API should list loaded model"
}

test_data_flow() {
    describe "End-to-end data flow"
    
    # Create test data
    test_data='{"input": "test message", "model": "sentiment-analysis"}'
    
    # Submit inference request
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        http://localhost:8080/api/v1/ai/inference)
    
    assert_contains "$response" "result" "Should return inference result"
    assert_contains "$response" "confidence" "Should return confidence score"
}

run_integration_tests() {
    test_full_platform_startup
    test_component_communication
    test_data_flow
    
    report_test_results
}

run_integration_tests
```

## Performance Testing

### Load Testing

```python
#!/usr/bin/env python3
# tests/performance/load/test_api_load.py

import asyncio
import aiohttp
import time
import statistics
from concurrent.futures import ThreadPoolExecutor

class LoadTester:
    def __init__(self, base_url, concurrent_users=10, test_duration=60):
        self.base_url = base_url
        self.concurrent_users = concurrent_users
        self.test_duration = test_duration
        self.results = []
    
    async def make_request(self, session, endpoint, payload=None):
        """Make a single request and measure response time"""
        start_time = time.time()
        try:
            if payload:
                async with session.post(endpoint, json=payload) as response:
                    await response.text()
                    return time.time() - start_time, response.status
            else:
                async with session.get(endpoint) as response:
                    await response.text()
                    return time.time() - start_time, response.status
        except Exception as e:
            return time.time() - start_time, 0
    
    async def user_scenario(self, user_id):
        """Simulate a user's behavior"""
        async with aiohttp.ClientSession() as session:
            end_time = time.time() + self.test_duration
            
            while time.time() < end_time:
                # Health check
                duration, status = await self.make_request(
                    session, f"{self.base_url}/health"
                )
                self.results.append(("health", duration, status))
                
                # AI inference request
                payload = {
                    "model": "sentiment-analysis",
                    "input": f"Test message from user {user_id}"
                }
                duration, status = await self.make_request(
                    session, f"{self.base_url}/api/v1/ai/inference", payload
                )
                self.results.append(("inference", duration, status))
                
                # Wait before next request
                await asyncio.sleep(1)
    
    async def run_load_test(self):
        """Run the load test with multiple concurrent users"""
        print(f"Starting load test with {self.concurrent_users} users for {self.test_duration} seconds")
        
        tasks = [
            self.user_scenario(i) for i in range(self.concurrent_users)
        ]
        
        await asyncio.gather(*tasks)
        
        # Analyze results
        self.analyze_results()
    
    def analyze_results(self):
        """Analyze and report test results"""
        if not self.results:
            print("No results to analyze")
            return
        
        # Group results by endpoint
        health_results = [r for r in self.results if r[0] == "health"]
        inference_results = [r for r in self.results if r[0] == "inference"]
        
        print("\n=== LOAD TEST RESULTS ===")
        print(f"Total requests: {len(self.results)}")
        print(f"Test duration: {self.test_duration} seconds")
        print(f"Concurrent users: {self.concurrent_users}")
        
        for endpoint, results in [("Health", health_results), ("Inference", inference_results)]:
            if not results:
                continue
                
            durations = [r[1] for r in results]
            statuses = [r[2] for r in results]
            
            success_rate = len([s for s in statuses if s == 200]) / len(statuses) * 100
            
            print(f"\n{endpoint} Endpoint:")
            print(f"  Requests: {len(results)}")
            print(f"  Success rate: {success_rate:.2f}%")
            print(f"  Avg response time: {statistics.mean(durations):.3f}s")
            print(f"  Min response time: {min(durations):.3f}s")
            print(f"  Max response time: {max(durations):.3f}s")
            print(f"  95th percentile: {statistics.quantiles(durations, n=20)[18]:.3f}s")

if __name__ == "__main__":
    load_tester = LoadTester("http://localhost:8080", concurrent_users=50, test_duration=120)
    asyncio.run(load_tester.run_load_test())
```

### Performance Benchmarking

```bash
#!/bin/bash
# tests/performance/benchmarks/platform_benchmarks.sh

source "$(dirname "$0")/../../lib/test_framework.sh"

benchmark_ai_inference() {
    describe "AI inference performance benchmark"
    
    local model="sentiment-analysis"
    local iterations=1000
    local start_time end_time duration
    
    # Load model
    ./scripts/ai_core_manager.sh load "$model"
    
    # Warm up
    for i in {1..10}; do
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"model": "'$model'", "input": "warmup test"}' \
            http://localhost:8080/api/v1/ai/inference >/dev/null
    done
    
    # Benchmark
    start_time=$(date +%s.%N)
    
    for i in $(seq 1 $iterations); do
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"model": "'$model'", "input": "benchmark test '$i'"}' \
            http://localhost:8080/api/v1/ai/inference >/dev/null
    done
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    local rps=$(echo "scale=2; $iterations / $duration" | bc)
    local avg_latency=$(echo "scale=3; $duration / $iterations * 1000" | bc)
    
    echo "AI Inference Benchmark Results:"
    echo "  Iterations: $iterations"
    echo "  Duration: ${duration}s"
    echo "  Requests per second: $rps"
    echo "  Average latency: ${avg_latency}ms"
}

benchmark_container_startup() {
    describe "Container startup performance"
    
    local iterations=50
    local total_time=0
    
    for i in $(seq 1 $iterations); do
        local start_time end_time duration
        
        start_time=$(date +%s.%N)
        ./scripts/chisel_container_boot.sh boot "test-$i" alpine:latest >/dev/null 2>&1
        ./scripts/chisel_container_boot.sh stop "test-$i" >/dev/null 2>&1
        end_time=$(date +%s.%N)
        
        duration=$(echo "$end_time - $start_time" | bc)
        total_time=$(echo "$total_time + $duration" | bc)
    done
    
    local avg_startup=$(echo "scale=3; $total_time / $iterations" | bc)
    
    echo "Container Startup Benchmark:"
    echo "  Iterations: $iterations"
    echo "  Average startup time: ${avg_startup}s"
}

run_benchmarks() {
    benchmark_ai_inference
    benchmark_container_startup
    
    # System resource usage
    echo -e "\nSystem Resource Usage:"
    echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "  Memory Usage: $(free | awk 'FNR==2{printf "%.2f%%", $3/($3+$4)*100}')"
    echo "  Disk Usage: $(df -h / | awk 'FNR==2{print $5}')"
}

run_benchmarks
```

## Security Testing

### Vulnerability Scanning

```python
#!/usr/bin/env python3
# tests/security/vulnerability/security_scanner.py

import subprocess
import json
import sys
from pathlib import Path

class SecurityScanner:
    def __init__(self):
        self.vulnerabilities = []
        self.scan_results = {}
    
    def scan_dependencies(self):
        """Scan for dependency vulnerabilities"""
        print("Scanning dependencies for vulnerabilities...")
        
        # Scan Python dependencies
        try:
            result = subprocess.run(
                ["pip", "list", "--format=json"],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                packages = json.loads(result.stdout)
                # Use safety or similar tool for vulnerability scanning
                self._check_python_vulnerabilities(packages)
        except Exception as e:
            print(f"Error scanning Python dependencies: {e}")
        
        # Scan system packages
        self._scan_system_packages()
    
    def scan_code_security(self):
        """Scan code for security issues"""
        print("Scanning code for security vulnerabilities...")
        
        # Scan shell scripts with shellcheck
        script_dir = Path("scripts")
        for script_file in script_dir.glob("*.sh"):
            self._scan_shell_script(script_file)
        
        # Scan for hardcoded secrets
        self._scan_for_secrets()
    
    def scan_container_security(self):
        """Scan container images for vulnerabilities"""
        print("Scanning container images...")
        
        # Use trivy or similar tool
        try:
            result = subprocess.run(
                ["docker", "images", "--format", "{{.Repository}}:{{.Tag}}"],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                images = result.stdout.strip().split('\n')
                for image in images:
                    if image and not image.startswith('<none>'):
                        self._scan_container_image(image)
        except Exception as e:
            print(f"Error scanning container images: {e}")
    
    def _scan_shell_script(self, script_path):
        """Scan individual shell script"""
        try:
            result = subprocess.run(
                ["shellcheck", "-f", "json", str(script_path)],
                capture_output=True, text=True
            )
            if result.stdout:
                issues = json.loads(result.stdout)
                for issue in issues:
                    if issue.get('level') in ['error', 'warning']:
                        self.vulnerabilities.append({
                            'type': 'shellcheck',
                            'file': str(script_path),
                            'line': issue.get('line'),
                            'message': issue.get('message'),
                            'severity': issue.get('level')
                        })
        except Exception as e:
            print(f"Error scanning {script_path}: {e}")
    
    def _scan_for_secrets(self):
        """Scan for hardcoded secrets"""
        secret_patterns = [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'api[_-]?key\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']'
        ]
        
        import re
        
        for script_file in Path("scripts").glob("*.sh"):
            with open(script_file, 'r') as f:
                content = f.read()
                for line_num, line in enumerate(content.split('\n'), 1):
                    for pattern in secret_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            self.vulnerabilities.append({
                                'type': 'hardcoded_secret',
                                'file': str(script_file),
                                'line': line_num,
                                'message': 'Potential hardcoded secret detected',
                                'severity': 'high'
                            })
    
    def generate_report(self):
        """Generate security scan report"""
        print("\n=== SECURITY SCAN REPORT ===")
        
        if not self.vulnerabilities:
            print("✓ No security vulnerabilities found")
            return True
        
        # Group by severity
        high_severity = [v for v in self.vulnerabilities if v.get('severity') == 'high']
        medium_severity = [v for v in self.vulnerabilities if v.get('severity') == 'warning']
        low_severity = [v for v in self.vulnerabilities if v.get('severity') == 'info']
        
        print(f"Total vulnerabilities found: {len(self.vulnerabilities)}")
        print(f"  High severity: {len(high_severity)}")
        print(f"  Medium severity: {len(medium_severity)}")
        print(f"  Low severity: {len(low_severity)}")
        
        print("\nDetailed findings:")
        for vuln in self.vulnerabilities:
            print(f"  [{vuln.get('severity', 'unknown').upper()}] {vuln.get('file')}:{vuln.get('line', 'N/A')}")
            print(f"    {vuln.get('message')}")
        
        # Return True if no high severity issues
        return len(high_severity) == 0

if __name__ == "__main__":
    scanner = SecurityScanner()
    scanner.scan_dependencies()
    scanner.scan_code_security()
    scanner.scan_container_security()
    
    success = scanner.generate_report()
    sys.exit(0 if success else 1)
```

## Continuous Integration Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: MobileOps CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: spiralgang/mobileops

jobs:
  code-quality:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: ShellCheck
      uses: ludeeus/action-shellcheck@master
      with:
        scandir: './scripts'
    
    - name: Code Security Scan
      run: |
        pip install bandit safety
        python tests/security/vulnerability/security_scanner.py

  unit-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install -r requirements-test.txt
    
    - name: Run unit tests
      run: |
        ./test_suite.sh unit
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: unit-test-results
        path: test-results/

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    services:
      redis:
        image: redis:alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup test environment
      run: |
        ./scripts/platform_launcher.sh init
        ./scripts/platform_launcher.sh start
    
    - name: Run integration tests
      run: |
        ./test_suite.sh integration
    
    - name: Cleanup
      if: always()
      run: |
        ./scripts/platform_launcher.sh stop

  performance-tests:
    runs-on: ubuntu-latest
    needs: integration-tests
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup performance test environment
      run: |
        ./scripts/platform_launcher.sh init
        ./scripts/platform_launcher.sh start
    
    - name: Run performance tests
      run: |
        ./test_suite.sh performance
    
    - name: Upload performance results
      uses: actions/upload-artifact@v3
      with:
        name: performance-results
        path: performance-results/

  security-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Container security scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload security scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-deploy:
    runs-on: ubuntu-latest
    needs: [code-quality, unit-tests, integration-tests]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build release package
      run: |
        ./scripts/build_release.sh init
        ./scripts/build_release.sh release
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push container images
      run: |
        ./scripts/build_release.sh images base
        docker tag mobileops-base:latest ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
    
    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: v${{ github.run_number }}
        release_name: Release v${{ github.run_number }}
        draft: false
        prerelease: false
```

### Test Automation Scripts

```bash
#!/bin/bash
# scripts/run_ci_tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

setup_test_environment() {
    log "Setting up test environment"
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Set up test configuration
    export MOBILEOPS_TEST_MODE=true
    export MOBILEOPS_LOG_LEVEL=DEBUG
    export MOBILEOPS_DATA_DIR="$PROJECT_ROOT/test-data"
    
    # Initialize platform for testing
    "$SCRIPT_DIR/platform_launcher.sh" init
}

run_code_quality_checks() {
    log "Running code quality checks"
    
    # ShellCheck for shell scripts
    if command -v shellcheck >/dev/null; then
        find "$SCRIPT_DIR" -name "*.sh" -exec shellcheck {} + \
            > "$TEST_RESULTS_DIR/shellcheck.log" 2>&1 || true
    fi
    
    # Security scanning
    if [[ -f "$PROJECT_ROOT/tests/security/vulnerability/security_scanner.py" ]]; then
        python3 "$PROJECT_ROOT/tests/security/vulnerability/security_scanner.py" \
            > "$TEST_RESULTS_DIR/security-scan.log" 2>&1 || true
    fi
}

run_test_suite() {
    local test_type="$1"
    
    log "Running $test_type tests"
    
    case "$test_type" in
        "unit")
            "$PROJECT_ROOT/test_suite.sh" unit > "$TEST_RESULTS_DIR/unit-tests.log" 2>&1
            ;;
        "integration")
            "$PROJECT_ROOT/test_suite.sh" integration > "$TEST_RESULTS_DIR/integration-tests.log" 2>&1
            ;;
        "performance")
            "$PROJECT_ROOT/test_suite.sh" performance > "$TEST_RESULTS_DIR/performance-tests.log" 2>&1
            ;;
        "security")
            "$PROJECT_ROOT/test_suite.sh" security > "$TEST_RESULTS_DIR/security-tests.log" 2>&1
            ;;
        "all")
            "$PROJECT_ROOT/test_suite.sh" all > "$TEST_RESULTS_DIR/all-tests.log" 2>&1
            ;;
    esac
}

generate_test_report() {
    log "Generating test report"
    
    cat > "$TEST_RESULTS_DIR/test-summary.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>MobileOps Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; }
        .fail { color: red; }
        .summary { background: #f0f0f0; padding: 10px; margin: 10px 0; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>MobileOps CI/CD Test Results</h1>
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Build: $(date)</p>
        <p>Commit: $(git rev-parse HEAD 2>/dev/null || echo "unknown")</p>
        <p>Branch: $(git branch --show-current 2>/dev/null || echo "unknown")</p>
    </div>
EOF
    
    # Add test results to report
    for log_file in "$TEST_RESULTS_DIR"/*.log; do
        if [[ -f "$log_file" ]]; then
            echo "<h3>$(basename "$log_file" .log)</h3>" >> "$TEST_RESULTS_DIR/test-summary.html"
            echo "<pre>" >> "$TEST_RESULTS_DIR/test-summary.html"
            head -100 "$log_file" >> "$TEST_RESULTS_DIR/test-summary.html"
            echo "</pre>" >> "$TEST_RESULTS_DIR/test-summary.html"
        fi
    done
    
    echo "</body></html>" >> "$TEST_RESULTS_DIR/test-summary.html"
    
    log "Test report generated: $TEST_RESULTS_DIR/test-summary.html"
}

cleanup_test_environment() {
    log "Cleaning up test environment"
    
    # Stop platform services
    "$SCRIPT_DIR/platform_launcher.sh" stop || true
    
    # Clean up test data
    rm -rf "$PROJECT_ROOT/test-data" || true
}

main() {
    local test_type="${1:-all}"
    
    log "Starting CI/CD test pipeline"
    
    # Set up error handling
    trap cleanup_test_environment EXIT
    
    # Run tests
    setup_test_environment
    run_code_quality_checks
    run_test_suite "$test_type"
    generate_test_report
    
    log "CI/CD test pipeline completed"
}

main "$@"
```

## Quality Gates and Metrics

### Test Coverage Requirements
- Unit test coverage: ≥ 80%
- Integration test coverage: ≥ 70%
- Critical path coverage: 100%

### Performance Benchmarks
- API response time: < 200ms (95th percentile)
- Container startup time: < 5 seconds
- AI inference latency: < 1 second
- System resource usage: < 80%

### Security Requirements
- Zero high-severity vulnerabilities
- All dependencies up to date
- Security scan pass rate: 100%
- Code quality score: ≥ 8.0/10

### Build and Deployment Criteria
- All tests must pass
- Code quality gates must be met
- Security scans must pass
- Performance benchmarks must be within limits
- Documentation must be up to date

## Best Practices

1. **Test-Driven Development**: Write tests before implementation
2. **Continuous Testing**: Run tests on every commit
3. **Fast Feedback**: Keep test execution time under 10 minutes
4. **Test Environment Parity**: Match production environment closely
5. **Automated Verification**: Minimize manual testing requirements
6. **Comprehensive Coverage**: Test happy paths, edge cases, and error conditions
7. **Performance Testing**: Include performance tests in CI pipeline
8. **Security First**: Integrate security testing throughout the pipeline

## Support and Resources

- **Testing Documentation**: [https://docs.mobileops.local/testing](https://docs.mobileops.local/testing)
- **CI/CD Pipeline**: [https://ci.mobileops.local](https://ci.mobileops.local)
- **Test Results Dashboard**: [https://dashboard.mobileops.local/tests](https://dashboard.mobileops.local/tests)
- **Quality Metrics**: [https://quality.mobileops.local](https://quality.mobileops.local)
- **Testing Best Practices**: [https://docs.mobileops.local/testing/best-practices](https://docs.mobileops.local/testing/best-practices)