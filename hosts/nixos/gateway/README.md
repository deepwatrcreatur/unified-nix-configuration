# Gateway Router Configuration

This directory contains the NixOS configuration for the gateway router, featuring RouterOS-inspired optimizations and comprehensive monitoring dashboards.

## Architecture

- **WAN Interface**: ens17 (DHCP from ISP)
- **LAN Interface**: ens16 (10.10.10.1/24)
- **Management Interface**: ens18 (192.168.100.100/24)

## Performance Optimizations

### FastTrack/FastPath (Flow Offloading)

Similar to RouterOS FastTrack, we use nftables flowtable to offload established connections:

```nftables
flowtable f {
  hook ingress priority 0;
  devices = { ens16, ens17, ens18 };
}

# In forward chain:
ip protocol { tcp, udp } flow add @f
```

This bypasses full connection tracking for established flows, dramatically improving throughput for large transfers.

### Hardware Offloading

Automatic configuration of NIC hardware features:
- **TSO** (TCP Segmentation Offload)
- **GSO** (Generic Segmentation Offload)
- **GRO** (Generic Receive Offload)
- **LRO** (Large Receive Offload)
- **Checksum offloading** (TX/RX)
- **Scatter-gather I/O**
- **Ring buffer optimization** (4096 packets)

### Queue Management

**CAKE** (Common Applications Kept Enhanced) on WAN for bufferbloat control:
```bash
tc qdisc replace dev ens17 root cake bandwidth 1Gbit
```

**FQ-CoDel** (Fair Queue with Controlled Delay) on LAN interfaces for internal traffic prioritization.

### TCP Optimizations

- **BBR** congestion control (Google's algorithm)
- TCP Fast Open (TFO)
- Increased socket buffers (32MB max)
- TCP window scaling
- Selective acknowledgements (SACK)
- ECN (Explicit Congestion Notification)

### Connection Tracking

Optimized for high-throughput routing:
- 262,144 maximum tracked connections
- Reduced timeout values for faster cleanup
- Efficient memory usage

### IRQ Balancing

Automatic distribution of network interrupts across CPU cores for optimal multi-core performance.

## Web Dashboards

### Main Dashboard (Port 8080)
http://gateway:8080

Central hub with quick links to all monitoring tools.

### Netdata (Port 19999)
http://gateway:19999

Real-time system and network monitoring:
- CPU, memory, disk usage
- Network interface traffic
- Per-application bandwidth
- Connection tracking stats
- System process monitoring

### Grafana (Port 3000)
http://gateway:3000

Professional analytics dashboards with Prometheus data:
- Historical traffic graphs
- Latency monitoring
- Connection statistics
- Custom alerts
- Beautiful visualizations

**Default Credentials**: admin/admin (change on first login)

### Prometheus (Port 9090)
http://gateway:9090

Metrics database and query interface:
- Node metrics (CPU, memory, network)
- Blackbox exporter (ICMP, HTTP checks)
- Custom metrics collection
- 30-day retention

### Technitium DNS (Port 5380)
http://gateway:5380

DNS and DHCP server management.

### Nginx Proxy Manager (Port 81)
http://gateway:81

Reverse proxy configuration and SSL certificate management.

## Command-Line Tools

### Traffic Analysis
```bash
# Real-time bandwidth by process
bandwhich

# Historical traffic statistics
vnstat
vnstat -l  # Live mode
vnstat -d  # Daily stats
vnstat -m  # Monthly stats

# Network load visualization
nload
bmon

# Interface bandwidth monitoring
iftop
nethogs

# Traffic per process
jnettop
```

### Performance Testing
```bash
# Internet speed test
speedtest-cli

# Local network performance
iperf3 -s  # Server mode
iperf3 -c <target>  # Client mode

# Network diagnostics
mtr google.com  # Combined traceroute + ping
```

### Hardware Inspection
```bash
# Check hardware offloads
ethtool -k ens17
ethtool -k ens16
ethtool -k ens18

# View ring buffer sizes
ethtool -g ens17

# Check queue discipline
tc qdisc show

# View connection tracking
conntrack -L
conntrack -S  # Statistics
```

### Kernel Network Status
```bash
# View sysctl settings
sysctl net.ipv4.tcp_congestion_control
sysctl net.netfilter.nf_conntrack_max

# Check loaded kernel modules
lsmod | grep -E 'bbr|cake|fq_codel'

# IRQ distribution
cat /proc/interrupts | grep eth
```

## Service Management

### Start/Stop Services
```bash
# Router optimizations
systemctl status router-hardware-offload
systemctl restart router-hardware-offload

# Monitoring services
systemctl status netdata
systemctl status grafana
systemctl status prometheus
systemctl status router-dashboard

# View logs
journalctl -u router-hardware-offload -f
journalctl -u netdata -f
```

### vnStat Database
```bash
# Update database manually
sudo vnstat -u

# Check service
systemctl status vnstat-update.timer
```

## Network Performance Tips

### Testing Throughput

1. **Between LAN hosts**:
   ```bash
   # Host 1
   iperf3 -s
   
   # Host 2
   iperf3 -c <host1-ip> -t 30 -P 10
   ```

2. **WAN throughput**:
   ```bash
   speedtest-cli
   ```

3. **Latency testing**:
   ```bash
   mtr -r -c 100 8.8.8.8
   ping -c 100 8.8.8.8 | tail -1
   ```

### Monitoring Flow Offload

Check if flows are being offloaded:
```bash
cat /proc/net/nf_conntrack | grep OFFLOAD
nft list flowtable inet filter f
```

### Bufferbloat Testing

Test with CAKE enabled:
```bash
# Run speed test while monitoring latency
speedtest-cli &
ping -i 0.2 8.8.8.8
```

Should see minimal latency increase during speed test (< 20ms is excellent).

## Firewall Rules

nftables configuration with:
- Stateful firewall on all interfaces
- NAT/masquerading for LAN → WAN
- SSH restricted to LAN/Management
- Web services accessible as configured
- Flow offloading for established connections

View active rules:
```bash
sudo nft list ruleset
```

## Troubleshooting

### High CPU Usage

Check if hardware offloads are enabled:
```bash
ethtool -k ens17 | grep offload
```

Check IRQ distribution:
```bash
cat /proc/interrupts | grep eth
systemctl status irqbalance
```

### Connection Tracking Full

Increase connection tracking table:
```bash
# Temporary
sudo sysctl -w net.netfilter.nf_conntrack_max=524288

# Permanent (already set in router-optimizations.nix)
```

View current usage:
```bash
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max
```

### Slow Throughput

1. Check queue discipline:
   ```bash
   tc -s qdisc show dev ens17
   ```

2. Test without QoS:
   ```bash
   sudo tc qdisc del dev ens17 root
   # Run tests
   sudo systemctl restart router-hardware-offload
   ```

3. Check MTU:
   ```bash
   ip link show | grep mtu
   ```

### Dashboard Not Loading

```bash
# Check services
systemctl status router-dashboard
systemctl status netdata
systemctl status grafana

# Check ports
ss -tulpn | grep -E '8080|19999|3000'

# View logs
journalctl -u router-dashboard -n 50
```

## Upgrading

To rebuild after configuration changes:
```bash
sudo nixos-rebuild switch --flake .#gateway
```

## Future Enhancements

Potential additions:
- **XDP programs** for DDoS protection
- **BPF traffic shaping** for per-IP QoS
- **Custom Grafana dashboards** with router-specific metrics
- **Alerting** via Prometheus Alertmanager
- **VPN** (WireGuard) integration
- **IDS/IPS** with Suricata
- **Traffic analysis** with ntopng

## References

- [nftables flowtable documentation](https://wiki.nftables.org/wiki-nftables/index.php/Flowtables)
- [CAKE QoS](https://www.bufferbloat.net/projects/codel/wiki/Cake/)
- [BBR Congestion Control](https://github.com/google/bbr)
- [Netdata documentation](https://learn.netdata.cloud/)
- [Grafana documentation](https://grafana.com/docs/)
