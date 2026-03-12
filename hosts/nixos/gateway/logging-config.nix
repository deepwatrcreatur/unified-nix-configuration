# Configure services to use spinning disk for logs
# This preserves SSD lifespan by redirecting all logging to HDD
{ config, pkgs, lib, ... }:

{
  # Netdata logs to HDD
  systemd.services.netdata = {
    environment = {
      NETDATA_LOG_DIR = "/var/log/gateway/netdata";
    };
  };

  # Grafana logs to HDD
  services.grafana.settings.paths = {
    logs = "/var/log/gateway/grafana";
  };

  # Prometheus data and logs to HDD (if not already configured)
  systemd.services.prometheus = {
    environment = {
      PROMETHEUS_LOG_DIR = "/var/log/gateway/prometheus";
    };
  };

  # Nginx Proxy Manager logs
  # (Podman container - configured via volumes in nginx-proxy-manager.nix if needed)
  
  # Fail2ban logs are handled by journald which is already redirected to HDD
  # fail2ban doesn't have a direct logpath option in NixOS
  
  # SSH logs are handled by journald which is already redirected to HDD
}
