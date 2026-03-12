#!/usr/bin/env bash
# Network interface status API for dashboard
# Returns JSON with interface information

set -euo pipefail

get_interface_info() {
    local iface=$1
    local ip_output=$(ip -j addr show dev "$iface" 2>/dev/null || echo "[]")
    local link_output=$(ip -j link show dev "$iface" 2>/dev/null || echo "[]")
    local stats_rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
    local stats_tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
    local stats_rx_packets=$(cat "/sys/class/net/$iface/statistics/rx_packets" 2>/dev/null || echo "0")
    local stats_tx_packets=$(cat "/sys/class/net/$iface/statistics/tx_packets" 2>/dev/null || echo "0")
    local stats_rx_errors=$(cat "/sys/class/net/$iface/statistics/rx_errors" 2>/dev/null || echo "0")
    local stats_tx_errors=$(cat "/sys/class/net/$iface/statistics/tx_errors" 2>/dev/null || echo "0")
    
    # Extract IPv4 addresses
    local ipv4=$(echo "$ip_output" | jq -r '.[0].addr_info[] | select(.family=="inet") | .local' 2>/dev/null | head -1 || echo "N/A")
    
    # Extract IPv6 addresses (global)
    local ipv6=$(echo "$ip_output" | jq -r '.[0].addr_info[] | select(.family=="inet6" and .scope=="global") | .local' 2>/dev/null | head -1 || echo "N/A")
    
    # Link state
    local state=$(echo "$link_output" | jq -r '.[0].operstate' 2>/dev/null || echo "UNKNOWN")
    
    # MTU
    local mtu=$(echo "$link_output" | jq -r '.[0].mtu' 2>/dev/null || echo "0")
    
    # Convert bytes to human readable
    local rx_human=$(numfmt --to=iec-i --suffix=B "$stats_rx" 2>/dev/null || echo "${stats_rx}B")
    local tx_human=$(numfmt --to=iec-i --suffix=B "$stats_tx" 2>/dev/null || echo "${stats_tx}B")
    
    cat <<EOF
{
  "interface": "$iface",
  "ipv4": "$ipv4",
  "ipv6": "$ipv6",
  "state": "$state",
  "mtu": $mtu,
  "stats": {
    "rx_bytes": $stats_rx,
    "tx_bytes": $stats_tx,
    "rx_bytes_human": "$rx_human",
    "tx_bytes_human": "$tx_human",
    "rx_packets": $stats_rx_packets,
    "tx_packets": $stats_tx_packets,
    "rx_errors": $stats_rx_errors,
    "tx_errors": $stats_tx_errors
  }
}
EOF
}

# Generate complete status
cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "uptime": "$(uptime -p)",
  "interfaces": {
    "wan": $(get_interface_info "ens17"),
    "lan": $(get_interface_info "ens16"),
    "mgmt": $(get_interface_info "ens18")
  },
  "connections": {
    "tracked": $(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo "0"),
    "max": $(cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo "0")
  }
}
EOF
