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

  # This host is NetworkManager-managed, so the shared systemd-networkd module
  # should not gate activation on networkd wait-online here.
  systemd.network.enable = lib.mkForce false;
  systemd.network.wait-online.enable = lib.mkForce false;

  services.tailscale.enable = true;
}
