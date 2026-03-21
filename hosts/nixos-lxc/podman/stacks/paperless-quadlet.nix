# hosts/nixos-lxc/podman/stacks/paperless-quadlet.nix
# Paperless-NGX using Quadlet (native podman systemd integration)
{ config, ... }:

{
  # Agenix secret for paperless database password
  age.secrets."paperless-db-password" = {
    file = ../../../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

  # Create persistent data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless/consume 0777 root root -"
    "d /var/lib/paperless/data 0777 root root -"
    "d /var/lib/paperless/pgdata 0777 root root -"
  ];

  # Quadlet network file
  environment.etc."containers/systemd/paperless.network".text = ''
    [Network]
    NetworkName=paperless
  '';

  # Quadlet pod file - handles port publishing for all containers
  environment.etc."containers/systemd/paperless.pod".text = ''
    [Pod]
    PodmanArgs=--infra-name=paperless-infra
    Network=paperless.network
    PublishPort=8000:8000
    
    [Install]
    WantedBy=multi-user.target default.target
  '';

  # Paperless-NGX container
  environment.etc."containers/systemd/paperless-ngx.container".text = ''
    [Unit]
    Description=Paperless-NGX Document Management
    Wants=network-online.target
    After=network-online.target
    
    [Container]
    Image=ghcr.io/paperless-ngx/paperless-ngx:latest
    Pod=paperless.pod
    Volume=/var/lib/paperless/data:/usr/src/paperless/data
    Volume=/var/lib/paperless/consume:/usr/src/paperless/consume
    EnvironmentFile=${config.age.secrets."paperless-db-password".path}
    Environment=PAPERLESS_REDIS=redis://localhost:6379
    Environment=PAPERLESS_DBENGINE=postgresql
    Environment=PAPERLESS_DBHOST=localhost
    Environment=PAPERLESS_DBNAME=paperless_user
    Environment=PAPERLESS_DBUSER=paperless_user
    Environment=PAPERLESS_URL=https://paperless-ngx.local
    
    [Service]
    Restart=always
    
    [Install]
    WantedBy=default.target
  '';

  # PostgreSQL container
  environment.etc."containers/systemd/paperless-db.container".text = ''
    [Unit]
    Description=Paperless PostgreSQL Database
    
    [Container]
    Image=postgres:15
    Pod=paperless.pod
    Volume=/var/lib/paperless/pgdata:/var/lib/postgresql/data
    EnvironmentFile=${config.age.secrets."paperless-db-password".path}
    Environment=POSTGRES_DB=paperless_user
    Environment=POSTGRES_USER=paperless_user
    
    [Service]
    Restart=always
    
    [Install]
    WantedBy=default.target
  '';

  # Redis container
  environment.etc."containers/systemd/paperless-redis.container".text = ''
    [Unit]
    Description=Paperless Redis Cache
    
    [Container]
    Image=redis:latest
    Pod=paperless.pod
    
    [Service]
    Restart=always
    
    [Install]
    WantedBy=default.target
  '';

  # Enable quadlet generator

  # Open firewall
  networking.firewall.allowedTCPPorts = [ 8000 ];
}
