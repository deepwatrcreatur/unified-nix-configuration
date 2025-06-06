# modules/nightscout.nix
{ config, pkgs, lib, ... }:

{
  # 1. Define the secrets file using sops-nix
  sops.secrets."MONGO_USER" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root"; # Ensure root can access for systemd service
    group = "root";
    mode = "0400";
  };
  sops.secrets."MONGO_PASSWORD" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0400";
  };
  sops.secrets."API_SECRET" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # 2. Define the containers
  virtualisation.oci-containers = {
    backend = "podman"; # Explicitly set Podman as the backend
    containers = {
      # The MongoDB database container
      mongo = {
        image = "mongo:4.4";
        autoStart = true;
        # Mount the persistent volume to the container's data directory
        volumes = [ "mongo-data:/data/db" ];
        # Use SOPS secrets via environment file in systemd service
        environment = {
          MONGO_INITDB_ROOT_USERNAME = "$(MONGO_USER)";
          MONGO_INITDB_ROOT_PASSWORD = "$(MONGO_PASSWORD)";
        };
      };

      # The Nightscout application container
      nightscout = {
        image = "nightscout/cgm-remote-monitor:latest";
        autoStart = true;
        ports = [ "1337:1337" ];
        # Use environment variables for secrets
        environment = {
          # Reference the mongo container by its name
          MONGO_CONNECTION = "mongodb://$(MONGO_USER):$(MONGO_PASSWORD)@mongo:27017/nightscout?authSource=admin";
          API_SECRET = "$(API_SECRET)";
          INSECURE_USE_HTTP = "true";
          DISPLAY_UNITS = "mmol/L";
        };
      };
    };
  };

  # 3. Systemd service overrides for Podman containers
  systemd.services."podman-mongo" = {
    wants = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/secrets/nightscout_env";
    };
  };

  systemd.services."podman-nightscout" = {
    wants = [ "sops-nix.service" "podman-mongo.service" ];
    after = [ "sops-nix.service" "podman-mongo.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/secrets/nightscout_env";
    };
  };

  # 4. Create an environment file for secrets
  environment.etc."secrets/nightscout_env".text = ''
    MONGO_USER=$(cat ${config.sops.secrets."MONGO_USER".path})
    MONGO_PASSWORD=$(cat ${config.sops.secrets."MONGO_PASSWORD".path})
    API_SECRET=$(cat ${config.sops.secrets."API_SECRET".path})
  '';

  # 5. Open the firewall port for Nightscout
  networking.firewall.allowedTCPPorts = [ 1337 ];
}
