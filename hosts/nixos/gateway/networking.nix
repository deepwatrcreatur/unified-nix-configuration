# Gateway networking configuration
{
  config,
  pkgs,
  lib,
  ...
}:

let
  interfaceNames = {
    wan = "ens17";
    lan = "ens16";
    management = "ens18";
  };

  delegatedPrefix = {
    Prefix = "::/64";
    PreferredLifetimeSec = 1800;
    ValidLifetimeSec = 3600;
  };

  mkRoutedLanNetwork =
    {
      name,
      device,
      ipv4Address,
      prefixDelegationMode ? "slaac",
      dns ? [ ],
      domains ? [ ],
      requiredForOnline ? null,
      extraRoutes ? [ ],
    }:
    {
      matchConfig.Name = device;
      address = [ ipv4Address ];
      routes = extraRoutes;
      linkConfig = lib.optionalAttrs (requiredForOnline != null) {
        RequiredForOnline = requiredForOnline;
      };
      networkConfig =
        {
          DHCPServer = false;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          # Routers and infrastructure boxes should keep stable IPv6 identities.
          IPv6PrivacyExtensions = "no";
        }
        // lib.optionalAttrs (dns != [ ]) { DNS = dns; }
        // lib.optionalAttrs (domains != [ ]) { Domains = domains; };
      ipv6SendRAConfig =
        if prefixDelegationMode == "managed" then
          {
            Managed = true;
            OtherInformation = true;
            EmitDNS = dns != [ ];
          }
        else
          {
            Managed = false;
            OtherInformation = false;
            EmitDNS = dns != [ ];
          };
      ipv6Prefixes = [ delegatedPrefix ];
    };
in
{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Disable systemd-resolved, use Technitium DNS directly
  services.resolved.enable = false;

  # DNS configuration - with fallback if Technitium is unavailable
  networking.nameservers = [
    "127.0.0.1"
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Create static resolv.conf with our nameservers and search domain
  environment.etc."resolv.conf".text = ''
    search deepwatercreature.com
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  # If Technitium fails, you can still SSH via IP: ssh 192.168.100.100

  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = true;

  # WAN interface - upstream IPv4 via DHCP, IPv6 via RA + DHCPv6 PD.
  systemd.network.networks."10-wan" = {
    matchConfig.Name = interfaceNames.wan;
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
      # Gateway should prefer stable public addresses over temporary ones.
      IPv6PrivacyExtensions = "no";
    };
    dhcpV6Config = {
      PrefixDelegationHint = "::/56";
      UseAddress = true;
    };
    ipv6AcceptRAConfig = {
      DHCPv6Client = "always";
      UseDNS = false;
    };
  };

  # Internal routed segments.
  systemd.network.networks."20-lan" = mkRoutedLanNetwork {
    name = "lan";
    device = interfaceNames.lan;
    ipv4Address = "10.10.10.1/16";
    dns = [ "127.0.0.1" ];
    domains = [ "deepwatercreature.com" ];
    requiredForOnline = "routable";
    extraRoutes = [
      {
        Destination = "10.10.0.0/16";
        Scope = "link";
      }
    ];
  };

  systemd.network.networks."30-management" = mkRoutedLanNetwork {
    name = "management";
    device = interfaceNames.management;
    ipv4Address = "192.168.100.100/24";
    prefixDelegationMode = "managed";
  };

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
