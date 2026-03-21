# hosts/nixos-lxc/podman/stacks/paperless-stack.nix
# Paperless-NGX using container-stack module
# Clean, declarative, agent-friendly format
{ config, lib, ... }:

let
  optSec = import ../../../../modules/helpers/optional-secrets.nix { inherit lib; };

  paperlessOidc = optSec.mkSecret "paperless-authentik-oidc" {
    file = ../../../../secrets-agenix/paperless-authentik-oidc.age;
  };
in

{
  # Agenix secret
  age.secrets."paperless-db-password" = {
    file = ../../../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

  age.secrets."paperless-authentik-oidc" = paperlessOidc.definition;

  # Declarative container stack - agents can easily convert docker-compose to this format!
  services.containerStacks.paperless = {
    network = "paperless";

    # Reference secrets (will be mounted in ALL containers)
    secrets = {
      "db-password".path = config.age.secrets."paperless-db-password".path;
    } // lib.optionalAttrs paperlessOidc.exists {
      "authentik-oidc".path = config.age.secrets."paperless-authentik-oidc".path;
    };

    # Containers (maps 1:1 with docker-compose services)
    containers = {
      paperless-ngx = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        ports = [ "8000:8000" ];
        volumes = [
          "/var/lib/paperless/data:/usr/src/paperless/data"
          "/var/lib/paperless/consume:/usr/src/paperless/consume"
        ];
        environment = {
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_DBNAME = "paperless_user";
          PAPERLESS_DBUSER = "paperless_user";
          PAPERLESS_TRUSTED_PROXIES = "10.10.10.1";
          PAPERLESS_URL = "https://paperless.deepwatercreature.com";
        };
        dependsOn = [ "paperless-db" "paperless-redis" ];
      };

      paperless-db = {
        image = "postgres:15";
        volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
        environment = {
          POSTGRES_DB = "paperless_user";
          POSTGRES_USER = "paperless_user";
        };
      };

      paperless-redis = {
        image = "redis:latest";
      };
    };

    # Persistent directories
    directories = [
      { path = "/var/lib/paperless/consume"; mode = "0777"; }
      { path = "/var/lib/paperless/data"; mode = "0777"; }
      { path = "/var/lib/paperless/pgdata"; mode = "0777"; }
    ];

    # Firewall
    firewall.allowedTCPPorts = [ 8000 ];
  };
}
