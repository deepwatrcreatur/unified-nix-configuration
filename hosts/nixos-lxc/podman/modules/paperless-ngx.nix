# /home/deepwatrcreatur/flakes/unified-nix-configuration/hosts/nixos-lxc/podman/modules/paperless-ngx.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.paperless-ngx;
in
{
  options.services.paperless-ngx = {
    enable = mkEnableOption "Enable Paperless-ngx";

    database = {
      user = mkOption {
        type = types.str;
        default = "paperless";
        description = "User for the Paperless-ngx database.";
      };
      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing the password for the Paperless-ngx database user.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create persistent data directories for Paperless-ngx
    systemd.tmpfiles.rules = [
      "d /var/lib/paperless/consume 0777 root root -"
      "d /var/lib/paperless/data 0777 root root -"
      "d /var/lib/paperless/pgdata 0777 root root -"
    ];

    # Define the Paperless-ngx containers
    virtualisation.oci-containers.containers = {
      paperless-ngx = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        hostname = "paperless-ngx";
        ports = [ "8000:8000" ];
        volumes = [
          "/var/lib/paperless/data:/usr/src/paperless/data"
          "/var/lib/paperless/consume:/usr/src/paperless/consume"
        ];
        environmentFiles = [
          cfg.database.passwordFile
        ];
        environment = {
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_DBNAME = cfg.database.user;
          PAPERLESS_DBUSER = cfg.database.user;
          PAPERLESS_URL = "https://paperless-ngx.local";
        };
        extraOptions = [ "--network=paperless" ];
        dependsOn = [ "paperless-db" "paperless-redis" ];
      };

      paperless-db = {
        image = "postgres:15";
        hostname = "paperless-db";
        volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
        environmentFiles = [
          cfg.database.passwordFile
        ];
        environment = {
          POSTGRES_DB = cfg.database.user;
          POSTGRES_USER = cfg.database.user;
        };
        extraOptions = [ "--network=paperless" ];
      };

      paperless-redis = {
        image = "redis:latest";
        hostname = "paperless-redis";
        extraOptions = [ "--network=paperless" ];
      };
    };

    # Define the paperless network
    virtualisation.podman.networks.paperless = {
      driver = "bridge";
    };

    # Open firewall port for Paperless-ngx
    networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}
