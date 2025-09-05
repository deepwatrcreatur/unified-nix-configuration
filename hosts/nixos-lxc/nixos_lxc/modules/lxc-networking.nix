{ config, lib, pkgs, ... }:

{
  # Enable networking with DHCP for LXC containers
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
  };
  
  # Ensure the interface comes up automatically
  systemd.services.lxc-networking = {
    description = "LXC Container Interface Setup";
    after = [ "network.target" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip link set eth0 up";
    };
  };
}