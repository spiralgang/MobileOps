#!/usr/bin/env bash

# AI Core Manager for MobileOps Platform
# Comprehensive AI inference engine management system
# Supports multiple AI backends, model orchestration, and resource allocation
# AI Core Manager for FileSystemds Platform
# Mobile-optimized AI inference, model management, and intelligent automation
# Supports on-device processing, edge AI, and cloud integration


set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/ai_core_manager.log"
AI_CONFIG_DIR="/etc/mobileops/ai"
MODEL_CACHE_DIR="/var/cache/mobileops/models"
PLUGIN_DIR="/opt/mobileops/ai-plugins"
RUNTIME_DIR="/var/run/mobileops/ai"
AI_ENDPOINTS_FILE="$AI_CONFIG_DIR/endpoints.json"
MODEL_REGISTRY="$AI_CONFIG_DIR/model_registry.json"

# AI Engine Types
declare -A AI_ENGINES=(
    ["tensorflow"]="TensorFlow Backend"
    ["pytorch"]="PyTorch Backend"
    ["onnx"]="ONNX Runtime"
    ["tflite"]="TensorFlow Lite"
    ["openvino"]="Intel OpenVINO"
    ["tensorrt"]="NVIDIA TensorRT"
    ["coreml"]="Apple Core ML"
    ["neural-net"]="Generic Neural Network"
    ["llm"]="Large Language Model"
    ["vision"]="Computer Vision Engine"
    ["speech"]="Speech Recognition"
    ["nlp"]="Natural Language Processing"
)

# Resource limits
MAX_GPU_MEMORY="80%"
MAX_CPU_CORES="4"
MAX_MEMORY_GB="8"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PROJECT_ROOT

# Mobile-friendly directory structure
if [[ -n "${ANDROID_DATA:-}" ]] || [[ -n "${ANDROID_ROOT:-}" ]]; then
    BASE_DIR="${ANDROID_DATA}/data/com.spiralgang.filesystemds"
else
    BASE_DIR="${HOME}/.local/share/filesystemds"
fi

LOG_DIR="$BASE_DIR/logs"
CONFIG_DIR="$BASE_DIR/config"
MODEL_CACHE_DIR="$BASE_DIR/cache/models"
AI_LIB_DIR="$BASE_DIR/lib/ai"
LOG_FILE="$LOG_DIR/ai_core_manager.log"
# Ensure directories exist
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$MODEL_CACHE_DIR" "$AI_LIB_DIR"
log() {
    local level="${1:-INFO}"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" | tee -a "$LOG_FILE"
    fi
}

check_dependencies() {
    log "INFO: Checking AI framework dependencies"
    
    local missing_deps
    # Check for Python and required modules
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check for specific AI frameworks
    if ! python3 -c "import tensorflow" 2>/dev/null; then
        log_debug "TensorFlow not available"
    fi
    
    if ! python3 -c "import torch" 2>/dev/null; then
        log_debug "PyTorch not available"
    fi
    
    # Check for GPU support
    if command -v nvidia-smi &> /dev/null; then
        log "INFO: NVIDIA GPU detected"
        export GPU_AVAILABLE=1
    else
        log "INFO: No NVIDIA GPU detected, using CPU only"
        export GPU_AVAILABLE=0
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

initialize_ai_environment() {
    log "INFO: Initializing AI environment"
    
    # Create necessary directories
    mkdir -p "$AI_CONFIG_DIR" "$MODEL_CACHE_DIR" "$PLUGIN_DIR" "$RUNTIME_DIR"
    
    # Set up model registry if it doesn't exist
    if [[ ! -f "$MODEL_REGISTRY" ]]; then
        cat > "$MODEL_REGISTRY" << EOF
{
    "models": {},
    "last_updated": "$(date -Iseconds)",
    "version": "1.0"
}
EOF
    fi
    
    # Set up endpoints configuration
    if [[ ! -f "$AI_ENDPOINTS_FILE" ]]; then
        cat > "$AI_ENDPOINTS_FILE" << EOF
{
    "endpoints": {
        "tensorflow": {
            "host": "localhost",
            "port": 8501,
            "protocol": "http",
            "enabled": false
        },
        "pytorch": {
            "host": "localhost", 
            "port": 8502,
            "protocol": "http",
            "enabled": false
        },
        "onnx": {
            "host": "localhost",
            "port": 8503,
            "protocol": "http",
            "enabled": false
        }
    }
}
EOF
    fi
}

start_ai_engine() {
    local engine_type="$1"
    local model_name="${2:-default}"
    local config_file="${3:-}"
    
    log "INFO: Starting AI engine: $engine_type with model: $model_name"
    
    if [[ ! -v AI_ENGINES["$engine_type"] ]]; then
        log_error "Unknown AI engine type: $engine_type"
        return 1
    fi
    
    # Check if engine is already running
    local pid_file="$RUNTIME_DIR/${engine_type}.pid"
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        log "INFO: AI engine $engine_type is already running"
        return 0
    fi
    
    case "$engine_type" in
        "tensorflow")
            start_tensorflow_engine "$model_name" "$config_file"
            ;;
        "pytorch")
            start_pytorch_engine "$model_name" "$config_file"
            ;;
        "onnx")
            start_onnx_engine "$model_name" "$config_file"
            ;;
        "tflite")
            start_tflite_engine "$model_name" "$config_file"
            ;;
        "openvino")
            start_openvino_engine "$model_name" "$config_file"
            ;;
        "tensorrt")
            start_tensorrt_engine "$model_name" "$config_file"
            ;;
        "coreml")
            start_coreml_engine "$model_name" "$config_file"
            ;;
        "neural-net")
            start_generic_neural_net "$model_name" "$config_file"
            ;;
        "llm")
            start_llm_engine "$model_name" "$config_file"
            ;;
        "vision")
            start_vision_engine "$model_name" "$config_file"
            ;;
        "speech")
            start_speech_engine "$model_name" "$config_file"
            ;;
        "nlp")
            start_nlp_engine "$model_name" "$config_file"
            ;;
        *)
            log_error "Engine type $engine_type not implemented"
            return 1
            ;;
    esac
    
    # Verify engine started successfully
    sleep 2
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        log "INFO: AI engine $engine_type started successfully"
        update_engine_status "$engine_type" "running"
        return 0
    else
        log_error "Failed to start AI engine $engine_type"
        return 1
    fi
}

start_tensorflow_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing TensorFlow engine"
    
    local model_path="$MODEL_CACHE_DIR/tensorflow/$model_name"
    local pid_file="$RUNTIME_DIR/tensorflow.pid"
    
    if [[ ! -d "$model_path" ]]; then
        log_error "TensorFlow model not found: $model_path"
        return 1
    fi
    
    # Start TensorFlow Serving
    nohup tensorflow_model_server \
        --rest_api_port=8501 \
        --model_name="$model_name" \
        --model_base_path="$(dirname "$model_path")" \
        > "$RUNTIME_DIR/tensorflow.log" 2>&1 &
    
    echo $! > "$pid_file"
    log "INFO: TensorFlow engine started (PID: $(cat "$pid_file"))"
}

start_pytorch_engine() {
    local model_name="$1" 
    local config_file="$2"
    
    log "INFO: Initializing PyTorch engine"
    
    local model_path="$MODEL_CACHE_DIR/pytorch/$model_name"
    local pid_file="$RUNTIME_DIR/pytorch.pid"
    
    if [[ ! -f "$model_path" ]]; then
        log_error "PyTorch model not found: $model_path"
        return 1
    fi
    
    # Start TorchServe
    nohup torchserve \
        --start \
        --model-store "$MODEL_CACHE_DIR/pytorch" \
        --models "$model_name" \
        --ts-config "$config_file" \
        > "$RUNTIME_DIR/pytorch.log" 2>&1 &
    
    echo $! > "$pid_file"
    log "INFO: PyTorch engine started (PID: $(cat "$pid_file"))"
}

start_onnx_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing ONNX Runtime engine"
    
    local model_path="$MODEL_CACHE_DIR/onnx/$model_name"
    local pid_file="$RUNTIME_DIR/onnx.pid"
    
    if [[ ! -f "$model_path" ]]; then
        log_error "ONNX model not found: $model_path"
        return 1
    fi
    
    # Start ONNX Runtime Server
    nohup python3 -c "
import onnxruntime as ort
from flask import Flask, request, jsonify
import numpy as np
import os

app = Flask(__name__)
session = ort.InferenceSession('$model_path')

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    inputs = {session.get_inputs()[0].name: np.array(data['input'])}
    outputs = session.run(None, inputs)
    return jsonify({'output': outputs[0].tolist()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8503)
" > "$RUNTIME_DIR/onnx.log" 2>&1 &
    
    echo $! > "$pid_file"
    log "INFO: ONNX engine started (PID: $(cat "$pid_file"))"
}

start_tflite_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing TensorFlow Lite engine"
    
    local model_path="$MODEL_CACHE_DIR/tflite/$model_name"
    local pid_file="$RUNTIME_DIR/tflite.pid"
    
    # This is a specialized case for mobile/edge deployment
    case "$model_name" in
        "mobilenet_v2")
            log "INFO: Loading MobileNet V2 model"
            ;;
        "efficientnet")
            log "INFO: Loading EfficientNet model"
            ;;
        "quantized_model")
            log "INFO: Loading quantized model for edge deployment"
            ;;
        *)
            log_error "Unknown TensorFlow Lite model: $model_name"
            return 1
            ;;
    esac
    
    echo $! > "$pid_file"
    log "INFO: TensorFlow Lite engine configured"
}

start_openvino_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing Intel OpenVINO engine"
    # OpenVINO specific implementation
}

start_tensorrt_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing NVIDIA TensorRT engine"
    # TensorRT specific implementation
}

start_coreml_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing Apple Core ML engine"
    # Core ML specific implementation
}

start_generic_neural_net() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing generic neural network engine"
    # Generic neural network implementation
}

start_llm_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing large language model engine"
    # LLM specific implementation
}

start_vision_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing computer vision engine"
    # Vision engine implementation
}

start_speech_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing speech recognition engine"
    # Speech engine implementation
}

start_nlp_engine() {
    local model_name="$1"
    local config_file="$2"
    
    log "INFO: Initializing natural language processing engine"
    # NLP engine implementation
}

stop_ai_engine() {
    local engine_type="$1"
    local pid_file="$RUNTIME_DIR/${engine_type}.pid"
    
    log "INFO: Stopping AI engine: $engine_type"
    
    if [[ ! -f "$pid_file" ]]; then
        log "INFO: Engine $engine_type is not running"
        return 0
    fi
    
    local pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        sleep 2
        
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
        fi
        
        rm -f "$pid_file"
        log "INFO: Engine $engine_type stopped"
        update_engine_status "$engine_type" "stopped"
    else
        log "INFO: Engine $engine_type was not running"
        rm -f "$pid_file"
    fi
}

load_model() {
    local engine_type="$1"
    local model_name="$2"
    local model_path="$MODEL_CACHE_DIR/$engine_type/$model_name"
    
    log "INFO: Loading AI model: $model_name for engine: $engine_type"
    
    if [[ ! -f "$model_path" ]]; then
        log_error "Model not found: $model_path"
        return 1
    fi
    
    # Update model registry
    python3 -c "
import json
import sys

registry_file = '$MODEL_REGISTRY'
try:
    with open(registry_file, 'r') as f:
        registry = json.load(f)
except:
    registry = {'models': {}, 'version': '1.0'}

registry['models']['$model_name'] = {
    'engine': '$engine_type',
    'path': '$model_path',
    'loaded': True,
    'timestamp': '$(date -Iseconds)'
}

with open(registry_file, 'w') as f:
    json.dump(registry, f, indent=2)
"
    
    log "INFO: Model $model_name loaded successfully"
}

unload_model() {
    local model_name="$1"
    
    log "INFO: Unloading AI model: $model_name"
    
    # Update model registry
    python3 -c "
import json

registry_file = '$MODEL_REGISTRY'
try:
    with open(registry_file, 'r') as f:
        registry = json.load(f)
    
    if '$model_name' in registry['models']:
        registry['models']['$model_name']['loaded'] = False
        registry['models']['$model_name']['unloaded_timestamp'] = '$(date -Iseconds)'
    
    with open(registry_file, 'w') as f:
        json.dump(registry, f, indent=2)
except Exception as e:
    print(f'Error updating registry: {e}')
"
    
    log "INFO: Model $model_name unloaded"
}

monitor_resources() {
    log "INFO: Monitoring AI core resources"
    
    # GPU monitoring
    if [[ "$GPU_AVAILABLE" == "1" ]]; then
        local gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
        local gpu_memory=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || echo "0,0")
        log "INFO: GPU Usage: ${gpu_usage}%, GPU Memory: ${gpu_memory}"
    fi
    
    # CPU and Memory monitoring
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local memory_usage=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100.0}')
    
    log "INFO: CPU Usage: ${cpu_usage}%, Memory Usage: ${memory_usage}%"
    
    # Check if resources are within limits
    check_resource_limits "$cpu_usage" "$memory_usage"
}

check_resource_limits() {
    local cpu_usage="$1"
    local memory_usage="$2"
    
    # Parse percentage values
    local cpu_limit=80
    local memory_limit=85
    
    if (( $(echo "$cpu_usage > $cpu_limit" | bc -l) )); then
        log_error "CPU usage ($cpu_usage%) exceeds limit ($cpu_limit%)"
    fi
    
    if (( $(echo "$memory_usage > $memory_limit" | bc -l) )); then
        log_error "Memory usage ($memory_usage%) exceeds limit ($memory_limit%)"
    fi
}

update_engine_status() {
    local engine_type="$1"
    local status="$2"
    
    local status_file="$RUNTIME_DIR/engine_status.json"
    
    python3 -c "
import json
import os

status_file = '$status_file'
engine = '$engine_type'
status = '$status'

if os.path.exists(status_file):
    with open(status_file, 'r') as f:
        data = json.load(f)
else:
    data = {'engines': {}}

data['engines'][engine] = {
    'status': status,
    'timestamp': '$(date -Iseconds)'
}

with open(status_file, 'w') as f:
    json.dump(data, f, indent=2)
"
}

list_available_engines() {
    log "INFO: Available AI engines:"
    for engine in "${!AI_ENGINES[@]}"; do
        log "  $engine: ${AI_ENGINES[$engine]}"
    done
}

list_loaded_models() {
    log "INFO: Loaded models:"
    
    if [[ ! -f "$MODEL_REGISTRY" ]]; then
        log "No models loaded"
        return
    fi
    
    python3 -c "
import json
try:
    with open('$MODEL_REGISTRY', 'r') as f:
        registry = json.load(f)
    
    loaded_models = {name: info for name, info in registry.get('models', {}).items() if info.get('loaded', False)}
    
    if not loaded_models:
        print('No models currently loaded')
    else:
        for name, info in loaded_models.items():
            print(f\"  {name}: {info.get('engine', 'unknown')} ({info.get('path', 'unknown path')})\")
except Exception as e:
    print(f'Error reading model registry: {e}')
"
}

health_check() {
    log "INFO: Performing AI system health check"
    
    local health_status="healthy"
    local issues=()
    
    # Check if essential directories exist
    for dir in "$AI_CONFIG_DIR" "$MODEL_CACHE_DIR" "$RUNTIME_DIR"; do
        if [[ ! -d "$dir" ]]; then
            issues+=("Missing directory: $dir")
            health_status="unhealthy"
        fi
    done
    
    # Check running engines
    local running_engines=0
    for engine in "${!AI_ENGINES[@]}"; do
        local pid_file="$RUNTIME_DIR/${engine}.pid"
        if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
            ((running_engines++))
        fi
    done
    
    log "INFO: Health status: $health_status"
    log "INFO: Running engines: $running_engines"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        log_error "Health check issues found:"
        for issue in "${issues[@]}"; do
            log_error "  $issue"
        done
        return 1
    fi
    
    return 0
}

cleanup() {
    log "INFO: Cleaning up AI Core Manager"
    
    # Stop all running engines
    for engine in "${!AI_ENGINES[@]}"; do
        stop_ai_engine "$engine"
    done
    
    # Clean up temporary files
    rm -f "$RUNTIME_DIR"/*.tmp
    
    log "INFO: Cleanup completed"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start <engine> [model] [config]  Start an AI engine with optional model and config
    stop <engine>                    Stop a specific AI engine
    load <engine> <model>            Load a model into an engine
    unload <model>                   Unload a model from memory
    monitor                          Monitor resource usage
    status                           Show system status
    health                           Perform health check
    list-engines                     List available AI engines
    list-models                      List loaded models
    cleanup                          Clean up and stop all engines

Examples:
    $0 start tensorflow mobilenet_v2
    $0 load pytorch bert-base-uncased
    $0 monitor
    $0 health
    
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

init_ai_core() {
    log_info "Initializing AI Core Manager"
    
    # Create AI configuration
    cat > "$CONFIG_DIR/ai_core.conf" << EOF
# FileSystemds AI Core Configuration
ai_core_version=1.0.0
initialization_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# AI Engine Configuration
inference_backend=cpu
model_cache_size=1GB
max_concurrent_inferences=2
memory_limit=512MB

# Mobile optimizations
power_aware=true
battery_conservation=true
thermal_throttling=true
background_processing=false

# Model management
auto_download_models=false
pointer_first_assets=true
require_explicit_fetch=true
EOF

    # Initialize model cache structure
    mkdir -p "$MODEL_CACHE_DIR"/{small,medium,large}
    
    # Create model manifest
    cat > "$MODEL_CACHE_DIR/manifest.json" << EOF
{
  "cache_version": "1.0.0",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "models": {},
  "total_size": "0MB",
  "cache_policy": "pointer-first"
}
EOF

    log_success "AI Core Manager initialized successfully"
}

start_ai_core() {
    log_info "Starting AI Core services"
    
    if [[ ! -f "$CONFIG_DIR/ai_core.conf" ]]; then
        log_error "AI Core not initialized. Run 'init' first."
        return 1
    fi
    
    # Start AI processing daemon (mock for now)
    log_info "Starting AI inference engine"
    
    # Create PID file for tracking
    echo $$ > "$BASE_DIR/ai_core.pid"
    
    log_success "AI Core services started"
}

stop_ai_core() {
    log_info "Stopping AI Core services"
    
    if [[ -f "$BASE_DIR/ai_core.pid" ]]; then
        local pid
        pid=$(cat "$BASE_DIR/ai_core.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$BASE_DIR/ai_core.pid"
        fi
    fi
    
    log_success "AI Core services stopped"
}

status_ai_core() {
    if [[ ! -f "$CONFIG_DIR/ai_core.conf" ]]; then
        echo "AI Core Status: NOT INITIALIZED"
        return 1
    fi
    
    if [[ -f "$BASE_DIR/ai_core.pid" ]]; then
        echo "AI Core Status: RUNNING"
    else
        echo "AI Core Status: STOPPED"
    fi
}

show_help() {
    cat << EOF
FileSystemds AI Core Manager - Mobile AI Platform

USAGE:
    $0 <command> [options]

COMMANDS:
    init        Initialize AI Core for first use
    start       Start AI processing services
    stop        Stop AI processing services
    status      Show AI Core status
    help        Show this help message

EXAMPLES:
    $0 init                 # Initialize AI Core
    $0 start                # Start AI services
    $0 status               # Check status


EOF
}

main() {

    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")" "$AI_CONFIG_DIR" "$MODEL_CACHE_DIR" "$RUNTIME_DIR"
    
    # Set up signal handlers
    trap cleanup EXIT
    trap 'log "INFO: Received SIGTERM, shutting down"; cleanup; exit 0' TERM
    trap 'log "INFO: Received SIGINT, shutting down"; cleanup; exit 0' INT
    
    log "INFO: AI Core Manager started"
    
    # Initialize environment
    if ! check_dependencies; then
        log_error "Dependency check failed"
        exit 1
    fi
    
    initialize_ai_environment
    
    case "${1:-status}" in
        "start")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 start <engine> [model] [config]"
                exit 1
            fi
            start_ai_engine "$2" "${3:-default}" "${4:-}"
            ;;
        "stop")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 stop <engine>"
                exit 1
            fi
            stop_ai_engine "$2"
            ;;
        "load")
            if [[ $# -lt 3 ]]; then
                log_error "Usage: $0 load <engine> <model>"
                exit 1
            fi
            load_model "$2" "$3"
            ;;
        "unload")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 unload <model>"
                exit 1
            fi
            unload_model "$2"

    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_ai_core
            ;;
        "start")
            start_ai_core

            ;;
        "stop")
            stop_ai_core
            ;;
        "status")
            log "INFO: AI Core Manager is running"
            monitor_resources
            list_loaded_models
            ;;
        "health")
            health_check
            ;;
        "list-engines")
            list_available_engines
            ;;
        "list-models")
            list_loaded_models
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            show_usage

            status_ai_core
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


# Execute main function if script is run directly

# Script entry point

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi