{ config, lib, ... }:
{
  # Shared defaults for router and router-backup.
  services.router-homelab = {
    enable = lib.mkDefault true;
    netdataAllowConnectionsFrom = lib.mkDefault "10.10.* 192.168.100.*";
  };

  router.monitoring = {
    grafanaDomain = lib.mkDefault "router.deepwatercreature.com";
    grafanaDataDir = lib.mkDefault "/var/log/router/grafana";
    listenAddress = lib.mkDefault "0.0.0.0";
    prometheusStateDir = lib.mkDefault "router-prometheus";
    prometheusBindMountPath = lib.mkDefault "/var/log/router/prometheus";
    prometheusRetentionSize = lib.mkDefault "40GB";
  };

  # Logs disk is on scsi1 (spinning disk), formatted by disko as disk-logs-logs.
  # router-log-storage handles the mount; disko only formats the partition.
  services.router-log-storage = {
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
}
