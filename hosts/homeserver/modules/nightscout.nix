# modules/nightscout.nix
{ config, pkgs, lib, ... }:

let
  # Define a reference to our sops-encrypted environment file
  nightscoutEnvFile = config.sops.secrets."nightscout_env".path;
in
{
  # 1. Define the secrets file using sops-nix
  sops.secrets."nightscout_env" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "dotenv"; # Exposes YAML keys as environment variables
  };

  virtualisation.oci-containers.volumes."mongo-data" = {
  };

  # 3. Define the containers
  virtualisation.oci-containers.containers = {
    # The MongoDB database container
    mongo = {
      image = "mongo:4.4";
      autoStart = true;
      # Mount the persistent volume to the container's data directory
      volumes = [ "mongo-data:/data/db" ];
      # Securely pass the MONGO_USER and MONGO_PASSWORD from our sops file
      environmentFile = nightscoutEnvFile;
    };

    # The Nightscout application container
    nightscout = {
      image = "nightscout/cgm-remote-monitor:latest";
      autoStart = true;
      ports = [ "1337:1337" ];
      # Securely pass API_SECRET and database credentials from our sops file
      environmentFile = nightscoutEnvFile;
      # Add any non-secret environment variables here
      environment = {
        # The hostname 'mongo' is automatically resolvable because NixOS
        # places both containers on the same internal network.
        MONGO_CONNECTION =
          "mongodb://nightscout:anwerkhan@mongo:27017/admin";
        INSECURE_USE_HTTP = "true";
        # Add other non-secret Nightscout variables here if needed
        DISPLAY_UNITS = "mmol";
      };
      # This is the declarative equivalent of `depends_on`.
      # It ensures the mongo container is started before nightscout.
      extraOptions = [ "--requires=mongo.service" ];
    };
  };

  # 4. Open the firewall port for Nightscout
  networking.firewall.allowedTCPPorts = [ 1337 ];
}
