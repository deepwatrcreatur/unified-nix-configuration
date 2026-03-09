# Gateway networking configuration
{ config, pkgs, lib, ... }:

{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Enable IP forwarding for routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Network interfaces using systemd-networkd
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;

  # WAN interface (ens17) - Get IP via DHCP from ISP
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens17";
    networkConfig.DHCP = "yes";
  };

  # LAN interface (ens16) - Static IP for internal network
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "ens16";
    address = [ "10.10.10.65/16" ];
    networkConfig = {
      DHCPServer = "no";
    };
  };

  # Management interface (ens18) - Get IP via DHCP for remote access
  systemd.network.networks."30-management" = {
    matchConfig.Name = "ens18";
    networkConfig.DHCP = "yes";
  };

  # NAT configuration for routing LAN traffic to WAN
  networking.nat = {
    enable = true;
    externalInterface = "ens17"; # WAN
    internalInterfaces = [ "ens16" ]; # LAN
  };
}
