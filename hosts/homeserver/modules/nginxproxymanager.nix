# hosts/homeserver/modules/nginxproxymanager.nix
{ config, lib, pkgs, ... }:

let
  # This makes the code cleaner. We'll refer to the enabled status.
  cfg = config.services.nginx-proxy-manager;

  # Get the path to the decrypted Cloudflare API key from your existing sops config.
  # This assumes your cloudflare-secrets.yaml has a key named 'api_key'.
  # If the key is named differently (e.g., 'global_api_key'), change it here.
  cloudflareApiKeyFile = config.sops.secrets.cloudflare_api_key.path;
in
{
  # Define the options for this module so you can enable/disable it easily.
  options.services.nginx-proxy-manager = {
    enable = lib.mkEnableOption "Enable Nginx Proxy Manager";
  };

  # This block only applies if you set services.nginx-proxy-manager.enable = true;
  config = lib.mkIf cfg.enable {

    # We need to define the sops secret here so this module knows about it.
    # This doesn't redefine it, just makes it accessible.
    sops.secrets.cloudflare_api_key = {
      sopsFile = ../../secrets/cloudflare-secrets.yaml; # Adjust path if needed
    };

    # Define the Nginx Proxy Manager container.
    virtualisation.oci-containers.containers."nginx-proxy-manager" = {
      image = "jc21/nginx-proxy-manager:latest";
      autoStart = true;
      ports = [
        "80:80"
        "443:443"
        "81:81"
      ];
      volumes = [
        # Standard NPM data and letsencrypt volumes
        "/var/lib/nginx-proxy-manager/data:/data"
        "/var/lib/nginx-proxy-manager/letsencrypt:/etc/letsencrypt"
        # Mount the decrypted Cloudflare API key file into the container
        # so NPM can use it for the DNS challenge.
        "${cloudflareApiKeyFile}:/secrets/cloudflare_api_key:ro"
      ];
    };

    # Ensure the data directories exist with the correct permissions.
    # This is good practice for services running as non-root.
    systemd.tmpfiles.rules = [
      "d /var/lib/nginx-proxy-manager 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/data 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/letsencrypt 0755 root root - -"
    ];
  };
}
