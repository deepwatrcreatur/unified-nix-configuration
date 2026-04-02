{
  lib,
  ...
}:
{
  imports = [
    (import ./role.nix {
      sshTarget = "ssh router.deepwatercreature.com";
      wanDevice = "enp6s17";
      lanDevice = "enp6s16";
      managementIpv4Address = "192.168.100.100/24";
      grafanaDomain = "router.deepwatercreature.com";
      grafanaDataDir = "/var/log/router/grafana";
      prometheusStateDir = "router-prometheus";
      prometheusBindMountPath = "/var/log/router/prometheus";
    })
  ];

  # DNS zone management with static hosts imported from external file.
  # Edit ./dns-zone.nix to manage one or more zones.
  services.router.dnsZones =
    let
      dnsConfig = import ./dns-zone.nix;
      defaultNetworks = [
        "10.10.10.0/24"
        "10.10.11.0/24"
      ];
      mkZone = zone: {
        nameserverIP = zone.nameserverIP or "10.10.10.1";
        allowDynamicUpdates = zone.allowDynamicUpdates or true;
        aliases = zone.aliases or { };
        staticHosts = lib.mapAttrs (_name: host: {
          ipAddress = host.ipv4;
          aliases = host.aliases or [ ];
        }) zone.hosts;
        reverseZone = {
          enable = zone.reverseZone.enable or true;
          networks = zone.reverseZone.networks or defaultNetworks;
        };
      };
    in
    if dnsConfig ? zones then
      lib.mapAttrs (_zoneName: zone: mkZone zone) dnsConfig.zones
    else
      {
        "${dnsConfig.domain}" = mkZone dnsConfig;
      };
}
