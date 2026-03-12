# Router performance optimizations inspired by RouterOS
# Includes fasttrack, hardware offload, queue management
{ config, pkgs, lib, ... }:

{
  # Kernel modules for advanced networking
  boot.kernelModules = [ 
    "tcp_bbr"           # Better congestion control
    "sch_fq"            # Fair queue scheduler
    "sch_fq_codel"      # FQ-CoDel queue discipline
    "sch_cake"          # CAKE queue discipline
    "act_bpf"           # BPF actions
    "cls_bpf"           # BPF classifier
    "ifb"               # Intermediate functional block (for ingress shaping)
  ];

  # Advanced kernel network tuning
  boot.kernel.sysctl = {
    # IP forwarding (already set but keeping for completeness)
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    
    # Connection tracking optimizations (fasttrack-like)
    "net.netfilter.nf_conntrack_max" = 262144;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 7200;
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait" = 15;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait" = 30;
    
    # TCP optimizations
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_rmem" = "4096 87380 33554432";
    "net.ipv4.tcp_wmem" = "4096 87380 33554432";
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_tw_reuse" = 1;
    
    # Core socket buffer sizes
    "net.core.rmem_default" = 262144;
    "net.core.rmem_max" = 33554432;
    "net.core.wmem_default" = 262144;
    "net.core.wmem_max" = 33554432;
    "net.core.netdev_max_backlog" = 5000;
    "net.core.optmem_max" = 65536;
    
    # Reduce TIME_WAIT buckets
    "net.ipv4.tcp_max_tw_buckets" = 200000;
    
    # Enable TCP window scaling
    "net.ipv4.tcp_window_scaling" = 1;
    
    # Enable selective acknowledgements
    "net.ipv4.tcp_sack" = 1;
    
    # Increase the maximum amount of memory allocated to shm
    "kernel.shmmax" = 68719476736;
    "kernel.shmall" = 4294967296;
    
    # Disable packet filtering on bridges (if used)
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
    
    # Increase local port range
    "net.ipv4.ip_local_port_range" = "10000 65535";
    
    # Enable ECN (Explicit Congestion Notification)
    "net.ipv4.tcp_ecn" = 1;
    
    # Protect against time-wait assassination
    "net.ipv4.tcp_rfc1337" = 1;
  };

  # Install performance monitoring and traffic control tools
  environment.systemPackages = with pkgs; [
    ethtool              # Hardware offload configuration
    iproute2             # tc (traffic control) for queue management
    tcpdump              # Packet analysis
    conntrack-tools      # Connection tracking utilities
    iperf3               # Network performance testing
    mtr                  # Network diagnostics
    bpftools             # BPF/XDP tools
    bpftrace             # Dynamic tracing
    numactl              # NUMA control
    irqbalance           # IRQ balancing for multi-core
  ];

  # Enable IRQ balancing for better multi-core performance
  services.irqbalance.enable = true;

  # Systemd service to enable hardware offloads and queue management
  systemd.services.router-hardware-offload = {
    description = "Enable hardware offloads and queue management for router";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Function to configure interface
      configure_interface() {
        local iface=$1
        local is_wan=$2
        
        # Enable hardware offloads
        ${pkgs.ethtool}/bin/ethtool -K $iface tso on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface gso on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface gro on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface ufo on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface lro on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface sg on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface tx on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -K $iface rx on 2>/dev/null || true
        
        # Increase ring buffer sizes for better performance
        ${pkgs.ethtool}/bin/ethtool -G $iface rx 4096 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -G $iface tx 4096 2>/dev/null || true
        
        # Enable interrupt coalescing
        ${pkgs.ethtool}/bin/ethtool -C $iface adaptive-rx on 2>/dev/null || true
        ${pkgs.ethtool}/bin/ethtool -C $iface adaptive-tx on 2>/dev/null || true
        
        # Configure queue discipline
        if [ "$is_wan" = "true" ]; then
          # WAN interface: use CAKE for better bufferbloat control
          ${pkgs.iproute2}/bin/tc qdisc replace dev $iface root cake bandwidth 1Gbit
        else
          # LAN interfaces: use fq_codel for internal traffic
          ${pkgs.iproute2}/bin/tc qdisc replace dev $iface root fq_codel
        fi
        
        echo "Configured $iface (WAN: $is_wan)"
      }
      
      # Wait for interfaces to be available
      sleep 2
      
      # Configure WAN interface
      if ip link show ens17 &>/dev/null; then
        configure_interface ens17 true
      fi
      
      # Configure LAN interfaces
      if ip link show ens16 &>/dev/null; then
        configure_interface ens16 false
      fi
      
      if ip link show ens18 &>/dev/null; then
        configure_interface ens18 false
      fi
      
      echo "Router hardware offload configuration complete"
      
      # Configure nftables flowtable for fasttrack offload
      # This must be done after interfaces are up
      ${pkgs.nftables}/bin/nft add flowtable inet filter f '{ hook ingress priority 0\; devices = { ens16, ens17, ens18 }\; }' 2>/dev/null || true
      ${pkgs.nftables}/bin/nft insert rule inet filter forward position 0 ip protocol { tcp, udp } flow add @f 2>/dev/null || true
      
      echo "Flowtable offload configured"
    '';
  };

  # BPF/XDP packet filtering for DDoS protection (can be extended)
  systemd.services.xdp-firewall = {
    description = "XDP-based early packet filtering";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Placeholder for XDP programs
      # XDP can drop packets at the NIC level before they reach the kernel
      # For now, just log that XDP is ready
      echo "XDP firewall ready (custom programs can be added)"
      
      # Example: Drop invalid packets early using nftables flowtable offload
      # This is handled in the nftables configuration
    '';
  };
}
