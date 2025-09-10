#!/bin/bash

# Network Configuration Script for MobileOps Platform
# Manages network interfaces, bridges, and routing for the platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/mobileops/network_configure.log"
NETWORK_CONFIG_DIR="/etc/mobileops/network"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

setup_bridge() {
    local bridge_name="$1"
    local bridge_ip="${2:-192.168.100.1/24}"
    
    log "INFO: Setting up bridge: $bridge_name"
    
    if ! ip link show "$bridge_name" >/dev/null 2>&1; then
        ip link add name "$bridge_name" type bridge
        ip link set "$bridge_name" up
        ip addr add "$bridge_ip" dev "$bridge_name"
        log "INFO: Bridge $bridge_name created with IP $bridge_ip"
    else
        log "INFO: Bridge $bridge_name already exists"
    fi
}

configure_container_networking() {
    log "INFO: Configuring container networking"
    
    # Setup container bridge
    setup_bridge "mobileops0" "172.16.0.1/16"
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Setup NAT for container traffic
    iptables -t nat -C POSTROUTING -s 172.16.0.0/16 ! -d 172.16.0.0/16 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 172.16.0.0/16 ! -d 172.16.0.0/16 -j MASQUERADE
    
    log "INFO: Container networking configured"
}

configure_vm_networking() {
    log "INFO: Configuring VM networking"
    
    # Setup VM bridge
    setup_bridge "br0" "192.168.200.1/24"
    
    # Configure DHCP range for VMs
    mkdir -p "$NETWORK_CONFIG_DIR"
    cat > "$NETWORK_CONFIG_DIR/dnsmasq-vm.conf" <<EOF
interface=br0
dhcp-range=192.168.200.100,192.168.200.200,12h
dhcp-option=3,192.168.200.1
dhcp-option=6,8.8.8.8,8.8.4.4
EOF
    
    log "INFO: VM networking configured"
}

setup_mobile_network() {
    local interface="$1"
    log "INFO: Setting up mobile network interface: $interface"
    
    # Configure mobile interface
    if ip link show "$interface" >/dev/null 2>&1; then
        ip link set "$interface" up
        dhclient "$interface" 2>/dev/null || log "WARN: DHCP failed for $interface"
        log "INFO: Mobile interface $interface configured"
    else
        log "ERROR: Mobile interface $interface not found"
        return 1
    fi
}

monitor_network() {
    log "INFO: Monitoring network status"
    
    echo "Network Interfaces:"
    ip link show | grep -E "^[0-9]+:" | while read -r line; do
        echo "  $line"
    done
    
    echo -e "\nBridge Status:"
    ip link show type bridge | grep -E "^[0-9]+:"
    
    echo -e "\nRouting Table:"
    ip route show
}

reset_network() {
    log "INFO: Resetting network configuration"
    
    # Remove custom bridges
    for bridge in mobileops0 br0 chisel0; do
        if ip link show "$bridge" >/dev/null 2>&1; then
            ip link delete "$bridge" 2>/dev/null || true
            log "INFO: Removed bridge: $bridge"
        fi
    done
    
    # Flush custom iptables rules
    iptables -t nat -F POSTROUTING 2>/dev/null || true
    
    log "INFO: Network reset completed"
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")" "$NETWORK_CONFIG_DIR"
    log "INFO: Network Configuration Manager started"
    
    case "${1:-monitor}" in
        "setup-container")
            configure_container_networking
            ;;
        "setup-vm")
            configure_vm_networking
            ;;
        "setup-mobile")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 setup-mobile <interface>"
                exit 1
            fi
            setup_mobile_network "$2"
            ;;
        "bridge")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 bridge <bridge_name> [ip_address]"
                exit 1
            fi
            setup_bridge "$2" "${3:-192.168.100.1/24}"
            ;;
        "monitor")
            monitor_network
            ;;
        "reset")
            reset_network
            ;;
        *)
            echo "Usage: $0 {setup-container|setup-vm|setup-mobile|bridge|monitor|reset} [args]"
            exit 1
            ;;
    esac
}

main "$@"