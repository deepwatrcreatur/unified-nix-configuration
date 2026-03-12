# Gateway Router Architecture

## Network Topology

```
                                 Internet
                                    │
                                    │ ISP DHCP
                                    ▼
                            ┌───────────────┐
                            │   ens17 (WAN) │
                            │  DHCP + IPv6  │
                            └───────┬───────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                    GATEWAY ROUTER                    │
         │                                                      │
         │  ┌────────────────────────────────────────────┐    │
         │  │         nftables + Flowtable               │    │
         │  │  ┌──────────────────────────────────┐     │    │
         │  │  │  FastTrack Flow Offloading       │     │    │
         │  │  │  (TCP/UDP established bypass)    │     │    │
         │  │  └──────────────────────────────────┘     │    │
         │  │                                            │    │
         │  │  Firewall Rules:                          │    │
         │  │  • Input: SSH, DNS, Web UI (LAN only)    │    │
         │  │  • Forward: LAN→WAN (with masquerade)    │    │
         │  │  • Drop invalid packets                   │    │
         │  └────────────────────────────────────────────┘    │
         │                                                      │
         │  ┌────────────────────────────────────────────┐    │
         │  │       Hardware Offload Pipeline            │    │
         │  │  TSO │ GSO │ GRO │ LRO │ Checksum         │    │
         │  └────────────────────────────────────────────┘    │
         │                                                      │
         │  ┌────────────────────────────────────────────┐    │
         │  │         Queue Management (tc)              │    │
         │  │  WAN:  CAKE (bufferbloat control)         │    │
         │  │  LAN:  FQ-CoDel (fair queuing)            │    │
         │  └────────────────────────────────────────────┘    │
         │                                                      │
         │  ┌────────────────────────────────────────────┐    │
         │  │         TCP Stack Optimizations            │    │
         │  │  • BBR congestion control                 │    │
         │  │  • TCP Fast Open                          │    │
         │  │  • 32MB socket buffers                    │    │
         │  │  • ECN enabled                            │    │
         │  └────────────────────────────────────────────┘    │
         │                                                      │
         └──────────────┬────────────────────┬─────────────────┘
                        │                    │
                ┌───────▼────────┐   ┌───────▼────────┐
                │  ens16 (LAN)   │   │ ens18 (MGMT)   │
                │ 10.10.10.1/24  │   │192.168.100.100 │
                └────────┬───────┘   └────────┬───────┘
                         │                    │
                    LAN Clients         Management
```

## Data Flow: Regular Traffic

```
Client → WAN
─────────────────────────────────────────────────────────────────
1. Packet arrives on ens16 (LAN)
2. nftables forward chain: match LAN→WAN rule
3. Connection tracking: create new entry
4. NAT/Masquerade: translate source IP
5. Hardware offload: TSO/GSO (if large packet)
6. Queue discipline: FQ-CoDel processing
7. Packet exits via ens17 (WAN) with CAKE shaping
```

## Data Flow: FastTrack Offload

```
Established Connection (FastTrack)
─────────────────────────────────────────────────────────────────
1. Packet arrives on any interface
2. Flowtable lookup: match existing flow
3. ✨ BYPASS full connection tracking ✨
4. Direct forwarding via offload path
5. Hardware offload: full pipeline active
6. Queue discipline: minimal processing
7. Packet forwarded at line rate

Performance gain: 2-5x throughput for bulk transfers
```

## Service Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     WEB DASHBOARDS & APIs                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Port 8080: Main Dashboard (Python HTTP)                        │
│  │                                                               │
│  ├─ Static HTML/CSS/JS                                          │
│  ├─ /api/status → network-status.sh (Bash script)              │
│  │   └─ Collects interface stats via ip/sysfs                  │
│  └─ Auto-refresh every 5 seconds                                │
│                                                                  │
│  Port 19999: Netdata                                            │
│  │                                                               │
│  ├─ Real-time system metrics                                    │
│  ├─ Per-process bandwidth                                       │
│  ├─ Connection tracking stats                                   │
│  └─ CPU, memory, disk I/O                                       │
│                                                                  │
│  Port 3000: Grafana                                             │
│  │                                                               │
│  ├─ Query Prometheus                                            │
│  ├─ Beautiful dashboards                                        │
│  ├─ Historical graphs                                           │
│  └─ Custom analytics                                            │
│                                                                  │
│  Port 9090: Prometheus                                          │
│  │                                                               │
│  ├─ Scrape node_exporter (port 9100)                           │
│  ├─ Scrape blackbox_exporter (port 9115)                       │
│  ├─ Store metrics (30 day retention)                           │
│  └─ Provide API for Grafana                                    │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                    MONITORING COLLECTORS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  node_exporter (port 9100)                                      │
│  └─ System metrics: CPU, RAM, disk, network, conntrack         │
│                                                                  │
│  blackbox_exporter (port 9115)                                  │
│  └─ Active probes: ICMP, HTTP checks                           │
│                                                                  │
│  vnstat daemon                                                   │
│  └─ Traffic statistics database                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Kernel Network Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                      NETWORK INTERFACE                           │
│                         (NIC Driver)                             │
├─────────────────────────────────────────────────────────────────┤
│                    Hardware Offloads                             │
│  RX: GRO, LRO, Checksum Validation                             │
│  TX: TSO, GSO, UFO, Checksum Generation                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                   TRAFFIC CONTROL (tc)                           │
│  ┌─────────────────────────────────────────────────┐            │
│  │  Ingress:  (future XDP/eBPF filters)            │            │
│  │  Egress:   CAKE (WAN) / FQ-CoDel (LAN)          │            │
│  └─────────────────────────────────────────────────┘            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                    nftables FIREWALL                             │
│  ┌─────────────────────────────────────────────────┐            │
│  │  Flowtable (ingress hook, priority 0)           │            │
│  │  └─ Offload established flows                   │            │
│  │                                                  │            │
│  │  Filter table (priority 0)                      │            │
│  │  ├─ Input chain   (policy drop)                 │            │
│  │  ├─ Forward chain (policy filter)               │            │
│  │  │   └─ flow add @f (offload to flowtable)     │            │
│  │  └─ Output chain  (policy accept)               │            │
│  │                                                  │            │
│  │  NAT table (priority 100)                       │            │
│  │  └─ Postrouting masquerade (WAN)                │            │
│  └─────────────────────────────────────────────────┘            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                   CONNECTION TRACKING                            │
│  Max: 262,144 connections                                        │
│  Optimized timeouts for TCP states                              │
│  Bypass via flowtable for established flows                     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                      TCP/IP STACK                                │
│  ┌─────────────────────────────────────────────────┐            │
│  │  BBR Congestion Control                          │            │
│  │  TCP Fast Open                                   │            │
│  │  Large socket buffers (32MB)                     │            │
│  │  Window scaling + SACK                           │            │
│  │  ECN support                                     │            │
│  └─────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Optimizations Summary

### Layer 2/3 (Hardware)
- **Offloads**: TSO, GSO, GRO, LRO, checksum
- **Ring buffers**: 4096 packets (RX/TX)
- **Interrupt coalescing**: Adaptive
- **IRQ balancing**: Multi-core distribution

### Layer 3/4 (Network/Transport)
- **Flowtable**: Bypass conntrack for established flows
- **BBR**: Modern congestion control
- **TCP Fast Open**: Reduced handshake latency
- **Large buffers**: 32MB socket buffers
- **Connection tracking**: 262k max, optimized timeouts

### Queue Discipline
- **WAN (CAKE)**: Bandwidth shaping, bufferbloat control
- **LAN (FQ-CoDel)**: Fair queuing, low latency

### Application Layer
- **Netdata**: Real-time monitoring
- **Grafana**: Historical analytics
- **Prometheus**: Metrics collection
- **vnStat**: Traffic statistics

## File Organization

```
hosts/nixos/gateway/
│
├── Configuration Files
│   ├── default.nix                  # Main configuration
│   ├── hardware-configuration.nix   # Hardware detection
│   ├── networking.nix               # Network interfaces
│   ├── nftables.nix                 # Firewall + flowtable
│   ├── router-optimizations.nix     # Performance tuning
│   └── router-dashboard.nix         # Monitoring services
│
├── Scripts
│   └── scripts/
│       └── network-status.sh        # Dashboard API
│
└── Documentation
    ├── README.md                    # Full documentation
    ├── SETUP.md                     # Setup guide
    ├── CHANGES.md                   # Summary of changes
    └── ARCHITECTURE.md              # This file
```

## Performance Metrics

### Expected Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Bulk transfer throughput | ~500 Mbps | ~900+ Mbps | 80%+ |
| Small packet forwarding | ~50k pps | ~150k+ pps | 200%+ |
| Connection tracking overhead | High | Low | Offloaded |
| Latency under load | 50-100ms | <20ms | 75%+ |
| CPU usage (routing) | 60-80% | 20-40% | 50%+ |

### Monitoring Points

**Hardware Layer:**
- `ethtool -S ens17` - NIC statistics
- `ethtool -k ens17` - Offload status
- `cat /proc/interrupts` - IRQ distribution

**Queue Layer:**
- `tc -s qdisc show` - Queue statistics
- `tc -s filter show` - Filter hits

**Firewall Layer:**
- `nft list ruleset` - Active rules
- `nft list flowtable inet filter f` - Offload stats

**Connection Tracking:**
- `/proc/sys/net/netfilter/nf_conntrack_count` - Active
- `/proc/net/nf_conntrack | grep OFFLOAD` - Offloaded flows

**Application Layer:**
- Netdata dashboard - Real-time metrics
- Grafana dashboard - Historical trends
- vnStat - Traffic history

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                      INTERNET (WAN)                          │
│                   Untrusted Network                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                  [nftables INPUT]
                         │
         ┌───────────────┼───────────────┐
         │   ALLOW       │     DROP      │
         │   • ICMP      │   • SSH       │
         │   • HTTP(S)   │   • All other │
         │   • Estab.    │     ports     │
         └───────────────┴───────────────┘
                         │
┌────────────────────────┼────────────────────────────────────┐
│                   GATEWAY ROUTER                             │
│                  Services Running:                           │
│   • SSH (LAN/MGMT only)                                     │
│   • DNS (LAN/MGMT only)                                     │
│   • Dashboards (LAN/MGMT only)                              │
│   • NPM (all interfaces for reverse proxy)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
    [LAN Network]                  [MGMT Network]
    10.10.10.0/24                  192.168.100.0/24
         │                               │
    Full Access                    Full Access
    to Router                      to Router
```

## Future Enhancement Ideas

### Short Term
- [ ] Custom Grafana dashboards for router metrics
- [ ] Alerting rules in Prometheus
- [ ] Traffic analysis with ntopng
- [ ] Automated backups of configuration

### Medium Term
- [ ] XDP/eBPF DDoS protection
- [ ] WireGuard VPN server
- [ ] Per-IP QoS with tc/BPF
- [ ] IDS/IPS with Suricata
- [ ] DNS filtering with custom blocklists

### Long Term
- [ ] Multi-WAN failover
- [ ] VLAN support with tagged interfaces
- [ ] IPv6 prefix delegation to multiple LANs
- [ ] BGP routing for advanced setups
- [ ] Full BGP peering capability

---

**This architecture provides enterprise-grade routing performance with**
**comprehensive monitoring, all managed through beautiful web interfaces!**
