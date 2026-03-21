# /home/deepwatrcreatur/flakes/unified-nix-configuration/hosts/nixos-lxc/podman/modules/paperless-ngx.nix
{ config, lib, pkgs, ... }:

with lib;

{
  # Agenix secret for paperless-ngx database
  age.secrets."paperless-db-password" = {
    file = ../../../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

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
        config.age.secrets."paperless-db-password".path
      ];
      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "paperless-db";
        PAPERLESS_DBNAME = "paperless_user";
        PAPERLESS_DBUSER = "paperless_user";
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
        config.age.secrets."paperless-db-password".path
      ];
      environment = {
        POSTGRES_DB = "paperless_user";
        POSTGRES_USER = "paperless_user";
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
  systemd.services.podman-network-paperless = {
    description = "Create podman network for paperless-ngx";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        /bin/sh -c '${pkgs.podman}/bin/podman network exists paperless || ${pkgs.podman}/bin/podman network create paperless'
      '';
    };
  };

  systemd.targets.paperless = {
    description = "Paperless-ngx target";
    requires = [ "podman-network-paperless.service" ];
    after = [ "podman-network-paperless.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."podman-paperless-ngx".wantedBy = [ "paperless.target" ];
  systemd.services."podman-paperless-db".wantedBy = [ "paperless.target" ];
  systemd.services."podman-paperless-redis".wantedBy = [ "paperless.target" ];

  # Open firewall port for Paperless-ngx
  networking.firewall.allowedTCPPorts = [ 8000 ];
}