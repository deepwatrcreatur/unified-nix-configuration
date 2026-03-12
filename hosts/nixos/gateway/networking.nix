# Gateway networking configuration
{ config, pkgs, lib, ... }:

{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Disable systemd-resolved, use Technitium DNS directly
  services.resolved.enable = false;
  networking.nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];
  
  # If Technitium fails, you can still SSH via IP: ssh 192.168.100.100

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
    # Request IPv6 prefix delegation
    dhcpV6Config = {
      PrefixDelegationHint = "::/56";  # Request /56 prefix from ISP (matches OPNsense)
      UseAddress = true;  # Also get an address for the gateway itself
    };
    ipv6AcceptRAConfig = {
      DHCPv6Client = "always";
      UseDNS = false;  # Use Technitium DNS instead
    };
  };

  # LAN interface (ens16) - Static IP for internal network
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "ens16";
    address = [ "10.10.10.1/24" ];
    routes = [
      {
        Destination = "10.10.10.0/24";
        Scope = "link";
      }
    ];
    networkConfig = {
      DHCPServer = "no";
      IPv6SendRA = true;
      DHCPPrefixDelegation = true;  # Enable receiving and using delegated prefixes
    };
    ipv6SendRAConfig = {
      Managed = false;  # Use SLAAC, not DHCPv6
      OtherInformation = false;
    };
    ipv6Prefixes = [
      {
        Prefix = "::/64";  # Announce a /64 from the delegated prefix
        PreferredLifetimeSec = 1800;
        ValidLifetimeSec = 3600;
      }
    ];
  };

  # Management interface (ens18) - Static IP for remote access
  systemd.network.networks."30-management" = {
    matchConfig.Name = "ens18";
    address = [ "192.168.100.100/24" ];
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

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
