# ./modules/nixos/services/zoraxy.nix
{ config, lib, pkgs, ... }:

let
  # A shorthand for accessing the module's configuration options.
  cfg = config.services.zoraxy;

  # This gets the runtime path to the decrypted Cloudflare API key file.
  # It assumes the secret in your YAML is named 'API_KEY', just like in your
  # cloudflare-ddns module. If it's named something else, change it here.
  cloudflareApiKeyFile = config.sops.secrets.API_KEY.path;
in
{
  # This block defines the configuration options for this module.
  options.services.zoraxy = {
    enable = lib.mkEnableOption "Enable the Zoraxy Reverse Proxy";
  };

  # This block applies the configuration only if you enable the service.
  config = lib.mkIf cfg.enable {

    # This tells NixOS that this module depends on the 'API_KEY' secret.
    # It ensures the secret is available when the module is evaluated.
    sops.secrets.API_KEY = {
      # This path should point to your existing encrypted secrets file.
      # Adjust the path if yours is located elsewhere.
      sopsFile = ../../secrets/cloudflare-secrets.yaml;
    };

    # This defines the Zoraxy container itself.
    virtualisation.oci-containers.containers.zoraxy = {
      image = "tobychui/zoraxy:latest";
      autoStart = true;
      ports = [
        "80:80"    # For HTTP traffic and ACME challenges
        "443:443"  # For HTTPS traffic
        "6789:6789" # For the Zoraxy admin web UI
      ];
      volumes = [
        # Persistent storage for Zoraxy's configuration and data
        "/var/lib/zoraxy/data:/app/data"
        # Persistent storage for TLS certificates
        "/var/lib/zoraxy/certs:/app/certs"
      ];

      # Zoraxy can read the API key directly from a file, which is very secure.
      # This is the same pattern used by your cloudflare-ddns service.
      environment = {
        # Your Cloudflare account email address.
        CLOUDFLARE_EMAIL = "deepwatrcreatur@gmail.com";
        # Tell Zoraxy where to find the API key file inside the container.
        CLOUDFLARE_API_KEY_FILE = "/run/secrets/cloudflare_api_key";
      };

      # Use extraOptions to securely mount the decrypted secret file into the container.
      extraOptions = [
        "--volume=${cloudflareApiKeyFile}:/run/secrets/cloudflare_api_key:ro"
      ];
    };

    # This ensures the directories for the volumes are created on the host
    # before the container starts.
    systemd.tmpfiles.rules = [
      "d /var/lib/zoraxy 0755 root root - -"
      "d /var/lib/zoraxy/data 0755 root root - -"
      "d /var/lib/zoraxy/certs 0755 root root - -"
    ];
  };
}
