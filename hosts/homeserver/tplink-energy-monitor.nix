# tplink-energy-monitor.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.tplink-energy-monitor;
in {
  options.services.tplink-energy-monitor = {
    enable = mkEnableOption "Enable the TP-Link Energy Monitor Docker Compose service";
    port = mkOption {
      type = types.str;
      default = "";
      description = "The port to use for the TP-Link Energy Monitor service";
    };
    logDir = mkOption {
      type = types.path;
      default = "/var/lib/tplink-energy-monitor/logs";
      description = "Directory to store logs for the TP-Link Energy Monitor service";
    };
  };

config = mkIf cfg.enable {
    systemd.services.tplink-energy-monitor = {
      description = "TP-Link Energy Monitor Podman Compose Service";
      after = [ "network.target" "podman.service" ];
      requires = [ "podman.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f /etc/tplink-energy-monitor/docker-compose.yml up";
        ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f /etc/tplink-energy-monitor/docker-compose.yml down";
        Restart = "always";
        WorkingDirectory = /etc/tplink-energy-monitor;
      };
      preStart = ''
        mkdir -p ${cfg.logDir}
        chmod 755 ${cfg.logDir}
      '';
    };

    environment.etc."tplink-energy-monitor/docker-compose.yml".text = ''
      version: '3.3'
      services:
        tplink-energy-monitor:
          container_name: tplink-energy-monitor
          network_mode: host
          build:
            context: /etc/tplink-energy-monitor
            dockerfile: Dockerfile
          volumes:
            - ${cfg.logDir}:/opt/tplink-monitor/logs
          restart: unless-stopped
          environment:
            - "PORT=${cfg.port}"
    '';

    environment.systemPackages = with pkgs; [
      podman
      podman-compose
    ];

    virtualisation.podman.enable = true;
  };
}
