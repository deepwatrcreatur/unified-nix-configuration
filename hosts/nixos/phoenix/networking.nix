{ config, lib, ... }:

{
  networking = {
    hostName = "phoenix";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        24800
        631
        5201
      ];
    };

    networkmanager.dns = "systemd-resolved";
  };

  services.tailscale.enable = true;
}
