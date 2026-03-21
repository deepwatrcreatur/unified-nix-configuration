# hosts/nixos-lxc/podman/stacks/paperless-stack.nix
# Paperless-NGX using container-stack module
# Clean, declarative, agent-friendly format
{ config, ... }:

{
  # Agenix secret
  age.secrets."paperless-db-password" = {
    file = ../../../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

  # Declarative container stack - agents can easily convert docker-compose to this format!
  services.containerStacks.paperless = {
    network = "paperless";

    # Reference secrets (will be mounted in ALL containers)
    secrets."db-password".path = config.age.secrets."paperless-db-password".path;

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
          PAPERLESS_URL = "https://paperless-ngx.local";
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
