#!/usr/bin/env bash
# Network interface status API for dashboard
# Returns JSON with interface information

set -euo pipefail

# Store previous stats for speed calculation
STATS_DIR="/run/router-dashboard"
mkdir -p "$STATS_DIR"

get_interface_info() {
    local iface=$1
    local stats_rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
    local stats_tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
    local stats_rx_packets=$(cat "/sys/class/net/$iface/statistics/rx_packets" 2>/dev/null || echo "0")
    local stats_tx_packets=$(cat "/sys/class/net/$iface/statistics/tx_packets" 2>/dev/null || echo "0")
    local stats_rx_errors=$(cat "/sys/class/net/$iface/statistics/rx_errors" 2>/dev/null || echo "0")
    local stats_tx_errors=$(cat "/sys/class/net/$iface/statistics/tx_errors" 2>/dev/null || echo "0")
    
    # Get IPv4 address using simple parsing
    local ipv4=$(ip -4 addr show dev "$iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    [ -z "$ipv4" ] && ipv4="N/A"
    
    # Get IPv6 global address
    local ipv6=$(ip -6 addr show dev "$iface" scope global 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-f:]+' | head -1)
    [ -z "$ipv6" ] && ipv6="N/A"
    
    # Get link state from operstate file (more reliable than ip command)
    local state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null | tr '[:lower:]' '[:upper:]')
    [ -z "$state" ] && state="UNKNOWN"
    
    # Get MTU
    local mtu=$(cat "/sys/class/net/$iface/mtu" 2>/dev/null || echo "0")
    
    # Calculate speed (bytes/sec since last check)
    local rx_speed=0
    local tx_speed=0
    local rx_speed_human="0 B/s"
    local tx_speed_human="0 B/s"
    
    local now=$(date +%s)
    local prev_file="$STATS_DIR/${iface}.prev"
    
    if [ -f "$prev_file" ]; then
        read -r prev_time prev_rx prev_tx < "$prev_file"
        local time_diff=$((now - prev_time))
        if [ "$time_diff" -gt 0 ]; then
            rx_speed=$(( (stats_rx - prev_rx) / time_diff ))
            tx_speed=$(( (stats_tx - prev_tx) / time_diff ))
            rx_speed_human=$(numfmt --to=iec-i --suffix=B/s "$rx_speed" 2>/dev/null || echo "${rx_speed} B/s")
            tx_speed_human=$(numfmt --to=iec-i --suffix=B/s "$tx_speed" 2>/dev/null || echo "${tx_speed} B/s")
        fi
    fi
    
    # Save current stats
    echo "$now $stats_rx $stats_tx" > "$prev_file"
    
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
    "rx_speed": $rx_speed,
    "tx_speed": $tx_speed,
    "rx_speed_human": "$rx_speed_human",
    "tx_speed_human": "$tx_speed_human",
    "rx_packets": $stats_rx_packets,
    "tx_packets": $stats_tx_packets,
    "rx_errors": $stats_rx_errors,
    "tx_errors": $stats_tx_errors
  }
}
EOF
}

# Get uptime in a compatible way
get_uptime() {
    if [ -r /proc/uptime ]; then
        local uptime_secs=$(cut -d. -f1 /proc/uptime)
        local days=$((uptime_secs / 86400))
        local hours=$(((uptime_secs % 86400) / 3600))
        local minutes=$(((uptime_secs % 3600) / 60))
        echo "up ${days}d ${hours}h ${minutes}m"
    else
        echo "unknown"
    fi
}

# Get hostname
get_hostname() {
    if [ -r /proc/sys/kernel/hostname ]; then
        cat /proc/sys/kernel/hostname
    else
        hostname 2>/dev/null || echo "unknown"
    fi
}

# Generate complete status
cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(get_hostname)",
  "uptime": "$(get_uptime)",
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
