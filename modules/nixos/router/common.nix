{ config, lib, ... }:
let
  hostsData = import ../../../lib/hosts.nix;
  routerHost = hostsData.hosts.router;
  backupHost = hostsData.hosts.router-backup;
in
{
  options.router.topology = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "Shared router inventory and network topology derived from lib/hosts.nix.";
  };

  config.router.topology = {
    domain = hostsData.domain;
    hosts = hostsData.hosts;
    routerHost = routerHost;
    backupHost = backupHost;
    networks = hostsData.networks;
  };

  # Shared defaults for router and router-backup.
  config.services.router-homelab = {
    enable = lib.mkDefault true;
    netdataAllowConnectionsFrom = lib.mkDefault "${hostsData.networks.lan.cidr} ${hostsData.networks.management.cidr}";
  };

  config.router.monitoring = {
    grafanaDomain = lib.mkDefault "router.${hostsData.domain}";
    grafanaDataDir = lib.mkDefault "/var/log/router/grafana";
    listenAddress = lib.mkDefault "0.0.0.0";
    prometheusStateDir = lib.mkDefault "router-prometheus";
    prometheusBindMountPath = lib.mkDefault "/var/log/router/prometheus";
    prometheusRetentionSize = lib.mkDefault "40GB";
  };

  # Logs disk is on scsi1 (spinning disk), formatted by disko as disk-logs-logs.
  # router-log-storage handles the mount; disko only formats the partition.
  config.services.router-log-storage = {
    enable = lib.mkDefault true;
    device = "/dev/disk/by-partlabel/disk-logs-logs";
    mountPoint = "/var/log/router";
    serviceName = "setup-router-logs";
    extraDirectories = [
      {
        name = "technitium";
        mode = "0777";
      }
      {
        name = "prometheus";
        user = "prometheus";
        group = "prometheus";
      }
      {
        name = "grafana";
        user = "grafana";
        group = "grafana";
      }
    ];
  };

  # Enable mDNS reflection across VLANs (LAN, Management, and IoT).
  # This allows discovery (AirPlay, Chromecast, etc.) to work across these segments.
  config.services.router-mdns = {
    enable = lib.mkDefault true;
    allowInterfaces =
      let
        mgmt = "ens18";
        lanDevice = config.services.router-networking.routedInterfaces.lan.device;
      in
      [
        lanDevice
        mgmt
      ]
      ++ lib.optionals (config.services.router-networking.routedInterfaces ? iot) [
        "${lanDevice}.20"
      ];
  };
}
