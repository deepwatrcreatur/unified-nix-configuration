{ config, lib, ... }:

{
  networking = {
    hostName = "workstation";
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        24800
        631
      ]; # Deskflow server and CUPS
    };

    # Tell NetworkManager to use systemd-resolved for DNS (gets from DHCP)
    networkmanager.dns = "systemd-resolved";
  };

  # Enable Avahi for service discovery (e.g., printers)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
