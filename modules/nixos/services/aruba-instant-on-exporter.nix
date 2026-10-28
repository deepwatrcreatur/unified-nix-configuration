# modules/nixos/services/aruba-instant-on-exporter.nix
# Declarative Prometheus exporter for HPE Aruba Instant On cloud portal API
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.aruba-instant-on-exporter;

  exporterScript = pkgs.writers.writePython3Bin "aruba-instant-on-exporter" {
    libraries = with pkgs.python3Packages; [
      requests
      prometheus-client
    ];
  } (builtins.readFile ./aruba-instant-on/aruba-instant-on-exporter.py);

in
{
  options.services.aruba-instant-on-exporter = {
    enable = mkEnableOption "Aruba Instant On cloud portal Prometheus exporter";

    port = mkOption {
      type = types.port;
      default = 9590;
      description = "Port to listen on for Prometheus scrapes.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind the HTTP server to.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open exporter port in firewall.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to environment file containing AIO_USERNAME and AIO_PASSWORD.";
    };

    scrapeIntervalSec = mkOption {
      type = types.int;
      default = 60;
      description = "Interval in seconds between cloud portal scrape cycles.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.aruba-instant-on-exporter = {
      description = "Aruba Instant On Cloud Portal Prometheus Exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        AIO_EXPORTER_PORT = toString cfg.port;
        AIO_SCRAPE_INTERVAL = toString cfg.scrapeIntervalSec;
      };

      serviceConfig = {
        ExecStart = "${exporterScript}/bin/aruba-instant-on-exporter";
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        CapabilityBoundingSet = "";
      };
    };
  };
}
