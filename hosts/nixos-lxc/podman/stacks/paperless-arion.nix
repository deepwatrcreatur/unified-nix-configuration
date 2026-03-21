# hosts/nixos-lxc/podman/stacks/paperless-arion.nix
# Paperless-NGX stack using Arion (docker-compose for Nix)
{ ... }:
{
  project.name = "paperless";

  networks.paperless = {};

  services = {
    paperless-ngx = {
      service = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        hostname = "paperless-ngx";
        container_name = "paperless-ngx";
        ports = [ "8000:8000" ];
        volumes = [
          "/var/lib/paperless/data:/usr/src/paperless/data"
          "/var/lib/paperless/consume:/usr/src/paperless/consume"
        ];
        env_file = [ "/run/agenix/paperless-db-password" ];
        environment = {
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_DBNAME = "paperless_user";
          PAPERLESS_DBUSER = "paperless_user";
          PAPERLESS_URL = "https://paperless-ngx.local";
        };
        depends_on = [ "paperless-db" "paperless-redis" ];
        networks = [ "paperless" ];
        restart = "unless-stopped";
      };
    };

    paperless-db = {
      service = {
        image = "postgres:15";
        hostname = "paperless-db";
        container_name = "paperless-db";
        volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
        env_file = [ "/run/agenix/paperless-db-password" ];
        environment = {
          POSTGRES_DB = "paperless_user";
          POSTGRES_USER = "paperless_user";
        };
        networks = [ "paperless" ];
        restart = "unless-stopped";
      };
    };

    paperless-redis = {
      service = {
        image = "redis:latest";
        hostname = "paperless-redis";
        container_name = "paperless-redis";
        networks = [ "paperless" ];
        restart = "unless-stopped";
      };
    };
  };
}
