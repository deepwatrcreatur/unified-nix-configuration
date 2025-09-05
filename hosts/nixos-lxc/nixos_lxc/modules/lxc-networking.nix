{ config, lib, pkgs, ... }:

{
  # Enable networking with DHCP for LXC containers
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
    dhcpcd.enable = true;
    nameservers = [ "8.8.8.8" "1.1.1.1" "10.10.10.1" ];
  };
  
  # Ensure proper network startup
  systemd.services.lxc-networking = {
    description = "LXC Container Networking Setup";
    after = [ "network.target" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "lxc-network-setup" ''
        # Bring up interface
        ${pkgs.iproute2}/bin/ip link set eth0 up
        
        # Start DHCP if not already running
        if ! ${pkgs.dhcpcd}/bin/dhcpcd -T eth0 >/dev/null 2>&1; then
          ${pkgs.dhcpcd}/bin/dhcpcd eth0
        fi
      '';
    };
  };
}