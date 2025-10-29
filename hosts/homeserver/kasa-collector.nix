# kasa-collector.nix
{ config, pkgs, lib, ... }:

let
  # Path to the sops-encrypted secrets file
  #secretsFile = config.sops.secrets."kasa_collector_influxdb_token".path;

in
{
  # Define the container
  virtualisation.oci-containers.containers.kasa-collector = {
    image = "lux4rd0/kasa-collector:latest";
    autoStart = true;
    environment = {
      KASA_COLLECTOR_INFLUXDB_TOKEN = "xL5JGvCFNgtW82ZQ1hVMWKNWAh2NCsJWnD_zjVTtZcgD0-Plytzu1i0QME3g200VNxFEgIUl2lZvDte-Rew-ww==";
      KASA_COLLECTOR_TPLINK_PASSWORD = "dontbeageek";
      KASA_COLLECTOR_INFLUXDB_BUCKET = "kasa";
      KASA_COLLECTOR_INFLUXDB_ORG = "deepwatercreature.com";
      KASA_COLLECTOR_INFLUXDB_TOKEN_FILE = "/run/secrets/kasa_collector_influxdb_token";  # Path inside the container
      KASA_COLLECTOR_INFLUXDB_URL = "http://10.10.10.183:8086";
      KASA_COLLECTOR_TPLINK_USERNAME = "kasa@deepwatercreature.com";  # Optional
      KASA_COLLECTOR_TPLINK_PASSWORD_FILE = "/run/secrets/kasa_collector_tplink_password";  # Path inside the container
      KASA_COLLECTOR_DEVICE_HOSTS = "10.10.14.12,10.10.14.13,10.10.14.14,10.10.14.15,10.10.14.18,10.10.14.19";  # Optional
      KASA_COLLECTOR_ENABLE_AUTO_DISCOVERY = "true";  # Optional
      TZ = "America/Toronto";
      LOG_LEVEL = "debug";  # Enable debug logging
    };
    # Use the decrypted secrets from sops
    #environmentFiles = [ secretsFile ];

    # Mount the decrypted secrets files into the container
    extraOptions = [
      #"-v" "${config.sops.secrets."kasa_collector_influxdb_token".path}:/run/secrets/kasa_collector_influxdb_token:ro"
      #"-v" "${config.sops.secrets."kasa_collector_tplink_password".path}:/run/secrets/kasa_collector_tplink_password:ro"
      "-v" "/run/secrets/kasa_collector_influxdb_token:/run/secrets/kasa_collector_influxdb_token:ro"   
      "-v" "/run/secrets/kasa_collector_tplink_password:/run/secrets/kasa_collector_tplink_password:ro"
    ];
  };

  # Configure sops to manage the secrets
  sops.secrets = {
    "kasa_collector_influxdb_token" = {
      sopsFile = ../secrets/kasa-secrets.yaml;  # Path to your sops-encrypted file
      owner = "root";
    };
    "kasa_collector_tplink_password" = {
      sopsFile = ../secrets/kasa-secrets.yaml;  # Path to your sops-encrypted file
      owner = "root";
    };
  };
}
