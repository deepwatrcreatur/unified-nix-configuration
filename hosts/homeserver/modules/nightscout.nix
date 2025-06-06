# modules/nightscout.nix
{ config, pkgs, lib, ... }:

{
  # 1. Define the secrets file using sops-nix
  sops.secrets."MONGO_USER" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
  };
  sops.secrets."MONGO_PASSWORD" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
  };
  sops.secrets."API_SECRET" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
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
        # Use SOPS secrets directly in environment variables
        environment = {
          MONGO_INITDB_ROOT_USERNAME = config.sops.secrets."MONGO_USER".path;
          MONGO_INITDB_ROOT_PASSWORD = config.sops.secrets."MONGO_PASSWORD".path;
        };
      };

      # The Nightscout application container
      nightscout = {
        image = "nightscout/cgm-remote-monitor:latest";
        autoStart = true;
        ports = [ "1337:1337" ];
        # Use SOPS secrets directly in environment variables
        environment = {
          # Reference the mongo container by its name; NixOS handles networking
          MONGO_CONNECTION = "mongodb://${config.sops.secrets."MONGO_USER".path}:${config.sops.secrets."MONGO_PASSWORD".path}@mongo:27017/nightscout?authSource=admin";
          API_SECRET = config.sops.secrets."API_SECRET".path;
          INSECURE_USE_HTTP = "true";
          DISPLAY_UNITS = "mg/dl"; # Changed to a valid Nightscout unit
        };
      };
    };
  };

  # 3. Open the firewall port for Nightscout
  networking.firewall.allowedTCPPorts = [ 1337 ];
}
