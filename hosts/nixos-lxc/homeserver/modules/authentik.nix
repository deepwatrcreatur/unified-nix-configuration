{ config, pkgs, ... }:

let
  hostProxy = import ../../../../modules/helpers/container-host-proxy.nix { inherit pkgs; };
in

{
  age.secrets."authentik-env" = {
    file = ../../../../secrets-agenix/authentik-env.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  virtualisation.oci-containers.backend = "podman";

  services.containerStacks.authentik = {
    network = "authentik";

    secrets."authentik-env".path = config.age.secrets."authentik-env".path;

    containers = {
      authentik-db = {
        image = "postgres:16";
        volumes = [
          "/var/lib/authentik/postgres:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_DB = "authentik";
          POSTGRES_USER = "authentik";
        };
      };

      authentik-server = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        volumes = [
          "/var/lib/authentik/media:/media"
        ];
        environment = {
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
        };
        cmd = [ "server" ];
        dependsOn = [ "authentik-db" ];
      };

      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.10.2";
        volumes = [
          "/var/lib/authentik/media:/media"
        ];
        environment = {
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
        };
        cmd = [ "worker" ];
        dependsOn = [ "authentik-db" ];
      };
    };

    directories = [
      { path = "/var/lib/authentik/media"; mode = "0777"; }
      { path = "/var/lib/authentik/postgres"; mode = "0777"; }
    ];

    firewall.allowedTCPPorts = [ 19000 ];
  };

  systemd.services.authentik-host-proxy = hostProxy.mkService {
    description = "Host-side Authentik proxy";
    containerName = "authentik-server";
    hostPort = 19000;
    containerPort = 9000;
  };
}
