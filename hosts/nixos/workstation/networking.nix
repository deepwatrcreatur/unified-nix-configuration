{ config, lib, ... }:

{
  networking = {
    hostName = "workstation";
    networkmanager.enable = true;
    search = [ "deepwatercreature.com" ];

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        24800
        631
        5201
      ]; # Deskflow server and CUPS
    };

    # Tell NetworkManager to use systemd-resolved for DNS (gets from DHCP)
    networkmanager.dns = "systemd-resolved";
  };

  # This host is NetworkManager-managed, so the shared systemd-networkd module
  # should not gate activation on networkd wait-online here.
  systemd.network.enable = lib.mkForce false;
  systemd.network.wait-online.enable = lib.mkForce false;

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
