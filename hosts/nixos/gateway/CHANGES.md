# Gateway Router Enhancements - Summary

## Overview

Your NixOS gateway router has been enhanced with RouterOS-inspired optimizations and comprehensive web dashboards.

## 🎯 Key Features Added

### 1. **FastTrack/Flow Offloading** (RouterOS FastTrack equivalent)
   - nftables flowtable bypasses full conntrack for established flows
   - Dramatically improves throughput for large transfers
   - Automatic offload for TCP/UDP connections

### 2. **Hardware Offloading Pipeline**
   - TSO, GSO, GRO, LRO offloading
   - Checksum offloading (TX/RX)
   - Optimized ring buffers (4096 packets)
   - Adaptive interrupt coalescing

### 3. **Advanced Queue Management**
   - **CAKE** on WAN: Bufferbloat control, bandwidth shaping
   - **FQ-CoDel** on LAN: Fair queuing, reduced latency
   - RouterOS-style integrated queuing

### 4. **TCP Optimizations**
   - BBR congestion control (Google's algorithm)
   - TCP Fast Open (TFO)
   - Optimized socket buffers (32MB max)
   - Reduced TIME_WAIT states

### 5. **Connection Tracking**
   - 262,144 max connections (configurable)
   - Optimized timeouts
   - Real-time monitoring

### 6. **Web Dashboards**

| Dashboard | Port | Purpose |
|-----------|------|---------|
| Main Dashboard | 8080 | Live stats, WAN IP, interface info |
| Netdata | 19999 | Real-time system monitoring |
| Grafana | 3000 | Historical analytics & graphs |
| Prometheus | 9090 | Metrics database |
| Technitium DNS | 5380 | DNS/DHCP management |
| Nginx Proxy Manager | 81 | Reverse proxy config |

### 7. **Traffic Analysis Tools**
   - vnStat: Historical traffic statistics
   - bandwhich: Per-process bandwidth (real-time)
   - iftop: Interface bandwidth monitor
   - nethogs: Per-process network usage
   - bmon: Bandwidth monitor with graphs
   - nload: Network load visualizer

## 📁 Files Created

```
hosts/nixos/gateway/
├── router-optimizations.nix    # Performance tuning (NEW)
├── router-dashboard.nix         # Web UI & monitoring (NEW)
├── scripts/
│   └── network-status.sh        # Dashboard API (NEW)
├── README.md                    # Full documentation (NEW)
├── SETUP.md                     # Quick setup guide (NEW)
├── default.nix                  # Updated: added imports
├── nftables.nix                 # Updated: added flowtable
└── networking.nix               # Updated: removed duplicate sysctl
```

## 🚀 Deployment

```bash
cd /home/deepwatrcreatur/flakes/unified-nix-configuration
sudo nixos-rebuild switch --flake .#gateway
```

## 📊 Access Dashboards

**From LAN (10.10.10.x) or Management (192.168.100.x):**

- Main Dashboard: http://gateway:8080 or http://10.10.10.1:8080
- Netdata: http://gateway:19999
- Grafana: http://gateway:3000 (default: admin/admin)
- Prometheus: http://gateway:9090

## 🔬 Verify Optimizations

```bash
# Check hardware offloads
ethtool -k ens17 | grep offload

# Verify queue discipline
tc qdisc show dev ens17    # Should show: cake
tc qdisc show dev ens16    # Should show: fq_codel

# Check flowtable
sudo nft list flowtable inet filter f

# View connection tracking
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max

# Test congestion control
sysctl net.ipv4.tcp_congestion_control  # Should show: bbr
```

## 📈 Performance Testing

### Throughput Test
```bash
# From LAN client
iperf3 -c <server> -t 30 -P 4
```

### Bufferbloat Test (CAKE effectiveness)
```bash
# Run simultaneously
speedtest-cli &
ping -c 20 8.8.8.8

# Good result: < 20ms latency increase
# Excellent result: < 10ms latency increase
```

### Traffic Monitoring
```bash
# Real-time per-process
sudo bandwhich

# Interface statistics
vnstat -l

# Live interface traffic
sudo iftop -i ens17
```

## 🎛️ Configuration Options

### Adjust WAN Bandwidth

Edit `router-optimizations.nix` line ~115:
```nix
${pkgs.iproute2}/bin/tc qdisc replace dev $iface root cake bandwidth 1Gbit
```
Change `1Gbit` to your actual speed (e.g., `500Mbit`, `200Mbit`)

### Increase Connection Tracking

Edit `router-optimizations.nix` line ~24:
```nix
"net.netfilter.nf_conntrack_max" = 524288;  # Double to 524k
```

## 🔍 Monitoring Commands

```bash
# Service status
systemctl status router-hardware-offload
systemctl status netdata
systemctl status grafana
systemctl status router-dashboard

# Network statistics
ip -s link show              # Interface stats
ss -s                         # Socket summary
conntrack -S                  # Connection tracking stats
vnstat                        # Traffic history

# Performance metrics
tc -s qdisc show              # Queue statistics
cat /proc/interrupts | grep ens  # IRQ distribution
ethtool -S ens17              # NIC statistics
```

## 🎨 Grafana Dashboard Setup

1. Access http://gateway:3000
2. Login: admin/admin (change password)
3. Import recommended dashboards:
   - **1860** - Node Exporter Full
   - **13320** - Network Traffic
   - Create custom for connection tracking

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Dashboard not loading | Check `systemctl status router-dashboard` |
| Flow offload not working | Verify `nft list flowtable inet filter f` |
| High latency | Adjust CAKE bandwidth to 90% of actual speed |
| Services not starting | Check logs: `journalctl -u <service>` |

## 📚 Documentation

- **README.md** - Comprehensive feature documentation
- **SETUP.md** - Detailed setup and configuration guide
- This file - Quick reference summary

## 🆚 RouterOS Feature Comparison

| RouterOS Feature | NixOS Implementation |
|------------------|---------------------|
| FastTrack | nftables flowtable offload |
| Hardware Offload | ethtool offload configuration |
| Queue Tree | CAKE + FQ-CoDel with tc |
| Firewall | nftables with connection tracking |
| Traffic Monitor | Netdata + Grafana + vnStat |
| Graphs | Grafana dashboards |
| Resource Monitor | Netdata real-time monitoring |
| Connection Tracking | nf_conntrack with optimizations |
| QoS | CAKE for WAN, FQ-CoDel for LAN |

## 🎉 What You Get

✅ **Performance**: Flow offloading, hardware acceleration, BBR  
✅ **Monitoring**: 5+ web dashboards with live stats  
✅ **Traffic Analysis**: Historical and real-time traffic graphs  
✅ **Interface Info**: Live WAN IP, RX/TX counters, status  
✅ **Low Latency**: CAKE bufferbloat control  
✅ **High Throughput**: Hardware offloads, optimized buffers  
✅ **Professional UI**: Beautiful Grafana dashboards  
✅ **Easy Management**: Web-based configuration  

## 🔜 Future Enhancements

Consider adding:
- XDP/eBPF for DDoS protection
- Custom Grafana dashboards
- WireGuard VPN integration
- IDS/IPS with Suricata
- Advanced traffic shaping (per-IP QoS)
- Alerting with Alertmanager

## 📞 Quick Reference

**All services configured ✅**  
**All syntax validated ✅**  
**Ready to deploy ✅**

Run: `sudo nixos-rebuild switch --flake .#gateway`

---

**Questions?** Check README.md or SETUP.md for detailed information.
