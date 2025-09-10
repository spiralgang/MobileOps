#!/bin/bash

# QEMU VM Boot Script for MobileOps Platform
# Handles virtual machine lifecycle and resource management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/qemu_vm_boot.log"
VM_CONFIG_DIR="/etc/mobileops/vms"
VM_STORAGE_DIR="/var/lib/mobileops/vms"
VM_RUN_DIR="/var/run/mobileops/qemu"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

prepare_vm_environment() {
    log "INFO: Preparing VM environment"
    mkdir -p "$VM_STORAGE_DIR" "$VM_RUN_DIR"
    
    # Check KVM support
    if [[ -c /dev/kvm ]]; then
        log "INFO: KVM acceleration available"
        KVM_ENABLED=true
    else
        log "WARN: KVM not available, using software emulation"
        KVM_ENABLED=false
    fi
}

create_vm() {
    local vm_name="$1"
    local disk_size="${2:-10G}"
    local vm_dir="$VM_STORAGE_DIR/$vm_name"
    
    log "INFO: Creating VM: $vm_name"
    mkdir -p "$vm_dir"
    
    # Create VM disk
    if [[ ! -f "$vm_dir/disk.qcow2" ]]; then
        log "INFO: Creating VM disk ($disk_size)"
        qemu-img create -f qcow2 "$vm_dir/disk.qcow2" "$disk_size"
    fi
    
    # Create VM config
    cat > "$VM_CONFIG_DIR/$vm_name.conf" <<EOF
VM_NAME=$vm_name
MEMORY=2048
CPUS=2
DISK_PATH=$vm_dir/disk.qcow2
NETWORK=bridge
KVM_ENABLED=$KVM_ENABLED
EOF
    
    log "INFO: VM $vm_name created successfully"
}

start_vm() {
    local vm_name="$1"
    local config_file="$VM_CONFIG_DIR/$vm_name.conf"
    
    log "INFO: Starting VM: $vm_name"
    
    if [[ ! -f "$config_file" ]]; then
        log "ERROR: VM config not found: $config_file"
        return 1
    fi
    
    source "$config_file"
    
    # Check if VM is already running
    if pgrep -f "qemu.*$vm_name" >/dev/null; then
        log "WARN: VM $vm_name is already running"
        return 0
    fi
    
    local qemu_args=(
        -name "$VM_NAME"
        -m "$MEMORY"
        -smp "$CPUS"
        -drive "file=$DISK_PATH,format=qcow2"
        -netdev "bridge,id=net0,br=br0"
        -device "virtio-net-pci,netdev=net0"
        -daemonize
        -pidfile "$VM_RUN_DIR/$vm_name.pid"
    )
    
    if [[ "$KVM_ENABLED" == "true" ]]; then
        qemu_args+=(-enable-kvm)
    fi
    
    log "INFO: Launching QEMU for $vm_name"
    qemu-system-x86_64 "${qemu_args[@]}"
    
    log "INFO: VM $vm_name started successfully"
}

stop_vm() {
    local vm_name="$1"
    local pid_file="$VM_RUN_DIR/$vm_name.pid"
    
    log "INFO: Stopping VM: $vm_name"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -TERM "$pid" 2>/dev/null; then
            log "INFO: Sent SIGTERM to VM $vm_name (PID: $pid)"
            sleep 5
            if kill -0 "$pid" 2>/dev/null; then
                log "WARN: VM didn't stop gracefully, forcing shutdown"
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$pid_file"
    fi
    
    log "INFO: VM $vm_name stopped"
}

list_vms() {
    log "INFO: Listing VMs"
    echo "Running VMs:"
    pgrep -f "qemu.*" | while read -r pid; do
        local cmd=$(ps -p "$pid" -o cmd --no-headers 2>/dev/null || echo "unknown")
        echo "PID: $pid, CMD: $cmd"
    done
    
    echo -e "\nConfigured VMs:"
    ls -1 "$VM_CONFIG_DIR"/*.conf 2>/dev/null | sed 's/.*\///;s/\.conf$//' || echo "No VMs configured"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$VM_CONFIG_DIR" "$VM_STORAGE_DIR" "$VM_RUN_DIR"
    log "INFO: QEMU VM Boot Manager started"
    
    case "${1:-list}" in
        "prepare")
            prepare_vm_environment
            ;;
        "create")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 create <vm_name> [disk_size]"
                exit 1
            fi
            create_vm "$2" "${3:-10G}"
            ;;
        "start")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 start <vm_name>"
                exit 1
            fi
            start_vm "$2"
            ;;
        "stop")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 stop <vm_name>"
                exit 1
            fi
            stop_vm "$2"
            ;;
        "list")
            list_vms
            ;;
        *)
            echo "Usage: $0 {prepare|create|start|stop|list} [args]"
            exit 1
            ;;
    esac
}

main "$@"