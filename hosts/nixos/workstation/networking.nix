{ config, lib, ... }:

{
  networking = {
    hostName = "workstation";
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [ 24800 ];  # Deskflow server
    };
  };

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
