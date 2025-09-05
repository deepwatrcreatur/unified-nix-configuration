{ config, lib, pkgs, ... }:

{
  # Enable networking with DHCP for LXC containers
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
    dhcpcd = {
      enable = lib.mkForce true;  # Override the global setting
      extraConfig = ''
        interface eth0
        static domain_name_servers=8.8.8.8 1.1.1.1 10.10.10.1
      '';
    };
    nameservers = [ "8.8.8.8" "1.1.1.1" "10.10.10.1" ];
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
      '';
    };
  };
}