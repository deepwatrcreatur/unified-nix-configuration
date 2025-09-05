{ config, lib, pkgs, ... }:

{
  # Enable networking with DHCP for LXC containers
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
    dhcpcd = {
      enable = lib.mkForce true;  # Override the global setting
      extraConfig = ''
        # Enable both IPv4 and IPv6
        ipv4
        ipv6
        
        interface eth0
        # Request IPv4 address via DHCP
        static domain_name_servers=8.8.8.8 1.1.1.1 10.10.10.1
      '';
    };
  };
  
  # Ensure proper network startup
  systemd.services.lxc-networking = {
    description = "LXC Container Networking Setup";
    after = [ "network.target" ];
    before = [ "dhcpcd.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "lxc-network-setup" ''
        # Create necessary directories
        mkdir -p /var/run/dhcpcd
        
        # Bring up interface
        ${pkgs.iproute2}/bin/ip link set eth0 up
        
        # Force IPv4 DHCP after interface is up
        sleep 2
        ${pkgs.dhcpcd}/bin/dhcpcd -4 eth0 || true
        
        # Ensure DNS is set up
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        echo "nameserver 10.10.10.1" >> /etc/resolv.conf
      '';
    };
  };
}