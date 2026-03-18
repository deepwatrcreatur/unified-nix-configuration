# Gateway networking configuration
{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Disable systemd-resolved, use Technitium DNS directly
  services.resolved.enable = false;

  # DNS configuration - with fallback if Technitium is unavailable
  # Note: With systemd-networkd, this needs special handling
  networking.nameservers = [
    "127.0.0.1"
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Create static resolv.conf with our nameservers and search domain
  environment.etc."resolv.conf".text = ''
    # Gateway DNS configuration
    # Primary: Technitium DNS on localhost
    # Fallback: Cloudflare and Google
    search deepwatercreature.com
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    nameserver 8.8.8.8
    options edns0
  '';

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
      PrefixDelegationHint = "::/56"; # Request /56 prefix from ISP (matches OPNsense)
      UseAddress = true; # Also get an address for the gateway itself
    };
    ipv6AcceptRAConfig = {
      DHCPv6Client = "always";
      UseDNS = false; # Use Technitium DNS instead
    };
  };

  # LAN interface (ens16) - Static IP for internal network
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "ens16";
    address = [ "10.10.10.1/16" ];
    routes = [
      {
        Destination = "10.10.0.0/16";
        Scope = "link";
      }
    ];
    networkConfig = {
      DHCPServer = "no";
      IPv6SendRA = true;
      DHCPPrefixDelegation = true; # Enable receiving and using delegated prefixes
      DNS = [ "127.0.0.1" ];
      Domains = [ "deepwatercreature.com" ];
    };
    ipv6SendRAConfig = {
      Managed = false; # Use SLAAC, not DHCPv6
      OtherInformation = false;
    };
    ipv6Prefixes = [
      {
        Prefix = "::/64"; # Announce a /64 from the delegated prefix
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
