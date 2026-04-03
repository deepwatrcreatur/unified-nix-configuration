{
  config,
  lib,
  ...
}:
let
  topology = config.router.topology;
  routerHost = topology.routerHost;
  backupHost = topology.backupHost;
  domain = topology.domain;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  lanIpv4Address = "${routerHost.ip}/${toString lanNetwork.prefixLength}";
  managementIpv4Address = "${routerHost.sshHostname}/${toString managementNetwork.prefixLength}";
  mkFqdn = label: "${label}.${domain}";
in
{
  imports = [
    (import ./role.nix {
      sshTarget = "ssh router";
      wanDevice = "router-wan";
      lanDevice = "router-lan";
      inherit lanIpv4Address managementIpv4Address;
      grafanaDomain = mkFqdn "router";
      grafanaDataDir = "/var/log/router/grafana";
      prometheusStateDir = "router-prometheus";
      prometheusBindMountPath = "/var/log/router/prometheus";
    })
  ];

  services.router-dashboard = {
    refreshInterval = 10;
    services = [
      "systemd-networkd"
      "sshd"
      "nftables"
      "caddy"
      "technitium-dns-server"
      "tailscaled"
      "fail2ban"
      "prometheus"
      "grafana"
      "netdata"
      "router-dashboard"
    ];
    links = lib.mkForce [
      {
        label = "Dashboard";
        url = "https://${mkFqdn "dashboard"}";
        icon = "🧭";
      }
      {
        label = "Homelab";
        url = "https://${mkFqdn "homelab"}";
        icon = "🏠";
      }
      {
        label = "Grafana";
        url = "https://${mkFqdn "grafana"}";
        icon = "📈";
      }
      {
        label = "DNS Admin Mgmt";
        url = "http://${routerHost.sshHostname}:5380/";
        icon = "🌍";
      }
      {
        label = "Prometheus Mgmt";
        url = "http://${routerHost.sshHostname}:9090/";
        icon = "🎯";
      }
      {
        label = "Netdata Mgmt";
        url = "http://${routerHost.sshHostname}:19999/";
        icon = "📊";
      }
      {
        label = "DNS Admin LAN";
        url = "http://${routerHost.ip}:5380/";
        icon = "🌍";
      }
      {
        label = "Prometheus LAN";
        url = "http://${routerHost.ip}:9090/";
        icon = "🎯";
      }
      {
        label = "Netdata LAN";
        url = "http://${routerHost.ip}:19999/";
        icon = "📊";
      }
      {
        label = "Router SSH";
        kind = "copy";
        copyText = "ssh router";
        icon = "🖥️";
      }
      {
        label = "Backup SSH";
        kind = "copy";
        copyText = "ssh router-backup";
        icon = "🛟";
      }
      {
        label = "Router Mgmt";
        kind = "copy";
        copyText = routerHost.sshHostname;
        icon = "🔧";
      }
      {
        label = "Backup Mgmt";
        kind = "copy";
        copyText = backupHost.sshHostname;
        icon = "🧰";
      }
      {
        label = "Tech Logs";
        url = "/logs/technitium.html";
        icon = "📜";
      }
      {
        label = "Fail2ban";
        url = "/status/fail2ban.html";
        icon = "🛡️";
      }
    ];
  };

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
        nameserverIP = zone.nameserverIP or routerHost.ip;
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
