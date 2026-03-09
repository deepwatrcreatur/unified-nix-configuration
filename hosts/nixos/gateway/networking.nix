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
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };
    dhcpV6Config = {
      PrefixDelegationHint = "::/60";  # Request /60 prefix from ISP
    };
    ipv6AcceptRAConfig = {
      DHCPv6Client = "always";
    };
  };

  # LAN interface (ens16) - Static IP for internal network
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "ens16";
    address = [ "10.10.10.1/16" ];
    networkConfig = {
      DHCPServer = "no";
      IPv6SendRA = true;
      DHCPPrefixDelegation = true;
    };
    ipv6SendRAConfig = {
      Managed = true;
      OtherInformation = true;
    };
    ipv6Prefixes = [
      {
        Prefix = "::/64";
        PreferredLifetimeSec = 1800;
        ValidLifetimeSec = 3600;
      }
    ];
  };

  # Management interface (ens18) - Get IP via DHCP for remote access
  systemd.network.networks."30-management" = {
    matchConfig.Name = "ens18";
    networkConfig.DHCP = "yes";
  };

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
