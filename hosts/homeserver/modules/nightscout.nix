# modules/nightscout.nix
{ config, pkgs, lib, ... }:

let
  nightscoutEnvFile = config.sops.secrets."nightscout_env".path;
in
{
  sops.secrets."nightscout_env" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "dotenv";
  };

  # This part is correct from our last step (updating the flake)
  virtualisation.oci-containers.volumes."mongo-data" = { };

  virtualisation.oci-containers.containers = {
    mongo = {
      image = "mongo:4.4";
      autoStart = true;
      volumes = [ "mongo-data:/data/db" ];
      environmentFile = nightscoutEnvFile;
    };

    nightscout = {
      image = "nightscout/cgm-remote-monitor:latest";
      autoStart = true;
      ports = [ "1337:1337" ];
      # Securely pass MONGO_USER and MONGO_PASSWORD from our sops file
      environmentFile = nightscoutEnvFile;

      # --- CHANGE IS HERE ---
      # Instead of one MONGO_CONNECTION string, we provide the parts.
      # The Nightscout image will assemble these into a correctly-escaped URI.
      environment = {
        # The hostname 'mongo' is automatically resolvable by other containers.
        MONGO_HOST = "mongo";
        # The database to authenticate against.
        MONGO_DATABASE = "admin";
        INSECURE_USE_HTTP = "true";
        # Add other non-secret Nightscout variables here if needed
        # e.g. DISPLAY_UNITS = "mmol";
      };
      # --- END OF CHANGE ---

      extraOptions = [ "--requires=mongo.service" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 1337 ];
}
