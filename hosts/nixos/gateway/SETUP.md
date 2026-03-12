# Gateway Router - Quick Setup Guide

## What Was Added

### 🚀 Performance Optimizations (`router-optimizations.nix`)

**RouterOS-style FastTrack:**
- nftables flowtable offload for established connections
- Hardware offloading (TSO, GSO, GRO, LRO)
- BBR congestion control
- Optimized connection tracking (262k max connections)

**Queue Management:**
- CAKE on WAN interface (bufferbloat control)
- FQ-CoDel on LAN interfaces
- Automatic ring buffer sizing (4096 packets)

**System Tuning:**
- TCP Fast Open
- Increased socket buffers (32MB)
- Optimized TCP timeouts
- IRQ balancing for multi-core

### 📊 Web Dashboards (`router-dashboard.nix`)

**Main Dashboard** - http://gateway:8080
- Live interface statistics with WAN IP display
- Connection tracking usage
- Real-time RX/TX counters
- Quick links to all services

**Netdata** - http://gateway:19999
- Real-time system monitoring
- Per-process bandwidth usage
- Connection tracking stats
- CPU, memory, disk I/O

**Grafana** - http://gateway:3000
- Historical analytics
- Custom dashboard support
- Prometheus data source
- Default: admin/admin

**Prometheus** - http://gateway:9090
- Metrics collection (30-day retention)
- Node exporter (system metrics)
- Blackbox exporter (ping/latency)
- Query interface

**Traffic Analysis:**
- vnStat for long-term traffic statistics
- Command-line tools: bandwhich, nethogs, iftop, bmon

## Building the Configuration

```bash
cd /home/deepwatrcreatur/flakes/unified-nix-configuration
sudo nixos-rebuild switch --flake .#gateway
```

## First-Time Setup

### 1. After Rebuild

Wait for all services to start:
```bash
systemctl status router-hardware-offload
systemctl status netdata
systemctl status grafana
systemctl status prometheus
systemctl status router-dashboard
```

### 2. Verify Hardware Offloads

```bash
# Check offload status
ethtool -k ens17 | grep on
ethtool -k ens16 | grep on
ethtool -k ens18 | grep on

# Check queue discipline
tc qdisc show dev ens17  # Should show: cake
tc qdisc show dev ens16  # Should show: fq_codel
```

### 3. Verify Flow Offloading

```bash
# Check if flowtable is active
sudo nft list flowtable inet filter f

# Generate some traffic, then check for offloaded flows
sudo cat /proc/net/nf_conntrack | grep OFFLOAD
```

### 4. Access Dashboards

From any device on LAN or Management network:
- **Main Dashboard**: http://gateway:8080 or http://10.10.10.1:8080
- **Netdata**: http://gateway:19999
- **Grafana**: http://gateway:3000 (setup password on first login)

## Performance Testing

### Baseline Test
```bash
# From a LAN client, test throughput
iperf3 -c <internet-server> -t 30 -P 4

# Check bufferbloat
speedtest-cli & sleep 1; ping -c 20 8.8.8.8
# Good: <20ms latency increase during speed test
# OK: 20-50ms
# Bad: >50ms (CAKE should prevent this)
```

### Connection Tracking
```bash
# Monitor connection usage
watch -n1 'cat /proc/sys/net/netfilter/nf_conntrack_count'

# View tracked connections
sudo conntrack -L | wc -l
```

### Traffic Monitoring
```bash
# Real-time per-process bandwidth
sudo bandwhich

# Interface traffic
sudo iftop -i ens17

# Historical stats
vnstat -l          # Live mode
vnstat -i ens17 -d # Daily stats for WAN
```

## Grafana Dashboard Import

### Recommended Dashboards

1. **Node Exporter Full** (ID: 1860)
   - Comprehensive system metrics
   - CPU, memory, disk, network

2. **Network Traffic** (ID: 13320)
   - Interface bandwidth graphs
   - Packet rates

3. **Connection Tracking** (Custom)
   - Create using Prometheus query: `node_nf_conntrack_entries`

To import:
1. Go to Grafana (port 3000)
2. Click + → Import
3. Enter dashboard ID
4. Select Prometheus as data source

## Customization

### Adjust WAN Bandwidth for CAKE

Edit `router-optimizations.nix`:
```nix
# Change from 1Gbit to your actual speed
${pkgs.iproute2}/bin/tc qdisc replace dev $iface root cake bandwidth 500Mbit
```

### Add Custom Monitoring

Add to `router-dashboard.nix` Prometheus scrape configs:
```nix
{
  job_name = "custom-exporter";
  static_configs = [{
    targets = [ "localhost:9999" ];
  }];
}
```

### Adjust Connection Tracking Limits

Edit `router-optimizations.nix`:
```nix
"net.netfilter.nf_conntrack_max" = 524288;  # Double the default
```

## Troubleshooting

### Dashboard Shows "Loading..."

```bash
# Check if script is executable
ls -l /etc/router-dashboard/network-status.sh

# Test script manually
sudo bash /etc/router-dashboard/network-status.sh

# Check dashboard service
systemctl status router-dashboard
journalctl -u router-dashboard -n 50
```

### Flow Offload Not Working

```bash
# Check kernel support
zcat /proc/config.gz | grep NF_FLOW

# Verify interfaces in flowtable
sudo nft list flowtable inet filter f

# Check for errors
journalctl -k | grep -i flow
```

### High Latency Despite CAKE

```bash
# Check if CAKE is active
tc -s qdisc show dev ens17

# Adjust bandwidth (set to 90% of actual speed)
sudo tc qdisc replace dev ens17 root cake bandwidth 450Mbit

# Test again
ping 8.8.8.8 &
speedtest-cli
```

### Grafana/Prometheus Not Starting

```bash
# Check logs
journalctl -u grafana -n 100
journalctl -u prometheus -n 100

# Check ports
ss -tulpn | grep -E '3000|9090'

# Restart services
sudo systemctl restart grafana
sudo systemctl restart prometheus
```

## Command Cheat Sheet

```bash
# View all router services
systemctl list-units | grep -E 'router-|netdata|grafana|prometheus'

# Restart all monitoring
sudo systemctl restart router-dashboard netdata grafana prometheus

# View nftables rules
sudo nft list ruleset

# Connection tracking stats
sudo conntrack -S

# Network statistics
ip -s link show
ss -s

# Check TCP congestion control
sysctl net.ipv4.tcp_congestion_control

# View IRQ assignments
cat /proc/interrupts | grep -E 'CPU|eth|ens'

# Test DNS
dig @127.0.0.1 google.com
```

## Files Created/Modified

**New Files:**
- `router-optimizations.nix` - Performance tuning
- `router-dashboard.nix` - Web UI and monitoring
- `scripts/network-status.sh` - API for dashboard
- `README.md` - Comprehensive documentation
- `SETUP.md` - This file

**Modified Files:**
- `default.nix` - Added imports for new modules
- `nftables.nix` - Added flowtable offload
- `networking.nix` - Removed duplicate sysctl (moved to optimizations)

## Next Steps

1. ✅ Build and deploy: `sudo nixos-rebuild switch --flake .#gateway`
2. 🔍 Check hardware offloads: `ethtool -k ens17`
3. 📊 Access dashboard: http://gateway:8080
4. ⚙️ Configure Grafana: http://gateway:3000
5. 📈 Monitor traffic: `vnstat -l`
6. 🧪 Run performance tests: `iperf3` / `speedtest-cli`

Enjoy your high-performance RouterOS-inspired NixOS router! 🚀
