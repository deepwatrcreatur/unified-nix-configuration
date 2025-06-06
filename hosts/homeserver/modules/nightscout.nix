# modules/nightscout.nix
{ config, pkgs, lib, ... }:

{
  # 1. Define the secrets file using sops-nix
  sops.secrets."mongo_user" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
  };
  sops.secrets."mongo_password" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
  };
  sops.secrets."api_secret" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
  };

  # 2. Define the containers
  virtualisation.oci-containers.containers = {
    # The MongoDB database container
    mongo = {
      image = "mongo:4.4";
      autoStart = true;
      # Mount the persistent volume to the container's data directory
      volumes = [ "mongo-data:/data/db" ];
      # Use SOPS secrets directly in environment variables
      environment = {
        MONGO_INITDB_ROOT_USERNAME = config.sops.secrets."mongo_user".path;
        MONGO_INITDB_ROOT_PASSWORD = config.sops.secrets."mongo_password".path;
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
        MONGO_CONNECTION = "mongodb://${config.sops.secrets."mongo_user".path}:${config.sops.secrets."mongo_password".path}@mongo:27017/admin";
        API_SECRET = config.sops.secrets."api_secret".path;
        INSECURE_USE_HTTP = "true";
        DISPLAY_UNITS = "mmol";
      };
      # Optional: Ensure mongo starts before nightscout (may not be needed)
      extraOptions = [ "--requires=mongo.service" ];
    };
  };

  # 3. Open the firewall port for Nightscout
  networking.firewall.allowedTCPPorts = [ 1337 ];
}
