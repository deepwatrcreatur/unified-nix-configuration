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

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
