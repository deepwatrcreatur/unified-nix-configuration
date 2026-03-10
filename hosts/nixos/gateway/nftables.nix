# Gateway firewall configuration using nftables
{ config, pkgs, lib, ... }:

{
  # Use nftables instead of iptables-based firewall
  networking.nftables.enable = true;
  networking.firewall.enable = false;

  # nftables ruleset for gateway functionality
  networking.nftables.ruleset = ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;
        
        # Allow established/related connections
        ct state {established, related} accept
        
        # Allow loopback
        iifname "lo" accept
        
        # Allow ICMP (ping)
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        
        # Allow DHCPv6 on WAN interface
        iifname "ens17" udp dport 546 accept
        
        # Allow SSH from LAN and management only (not WAN)
        iifname {"ens16", "ens18"} tcp dport 22 accept
        
        # Allow DNS and DHCP on LAN and management interfaces
        iifname {"ens16", "ens18"} udp dport {53, 67, 68, 547} accept
        iifname {"ens16", "ens18"} udp sport {67, 68} accept
        iifname {"ens16", "ens18"} tcp dport 53 accept
        
        # Allow Technitium web UI on LAN and management
        iifname {"ens16", "ens18"} tcp dport {5380, 53443} accept
        
        # Allow NPM web UI on LAN and management
        iifname {"ens16", "ens18"} tcp dport 81 accept
        
        # Allow HTTP/HTTPS from WAN and LAN for NPM reverse proxy
        tcp dport {80, 443} accept
      }
      
      chain forward {
        type filter hook forward priority 0; policy drop;
        
        # Allow established/related connections (return traffic)
        ct state {established, related} accept
        
        # Drop invalid packets
        ct state invalid drop
        
        # Allow forwarding from LAN to WAN
        iifname "ens16" oifname "ens17" accept
        
        # Allow forwarding from management to WAN
        iifname "ens18" oifname "ens17" accept
      }
      
      chain output {
        type filter hook output priority 0; policy accept;
      }
    }
    
    table ip nat {
      chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        
        # Masquerade IPv4 traffic from LAN going to WAN
        oifname "ens17" masquerade
      }
    }
  '';
}
