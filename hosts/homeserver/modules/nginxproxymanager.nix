# ./modules/nixos/services/nginxproxymanager.nix
{ config, lib, pkgs, ... }:

let
  # This makes the code cleaner. We'll refer to the options block.
  cfg = config.services.nginx-proxy-manager;
in
{
  # This 'options' block defines the configuration interface for this module.
  options.services.nginx-proxy-manager = {
    enable = lib.mkEnableOption "Enable Nginx Proxy Manager";
    
    # We can add more options here in the future if needed,
    # like package version, data directory, etc.
  };

  # This 'config' block applies the settings if the module is enabled.
  # It is guaranteed to run AFTER the 'options' block has been evaluated.
  config = lib.mkIf cfg.enable {

    # This makes the API_KEY secret available to this module.
    sops.secrets.API_KEY = {
      # Assuming the path is relative to the flake root.
      # You might need to adjust this path based on your structure.
      sopsFile = ./secrets/cloudflare-secrets.yaml; 
    };

    virtualisation.oci-containers.containers."nginx-proxy-manager" = {
      image = "jc21/nginx-proxy-manager:latest";
      autoStart = true;
      ports = [
        "80:80"
        "443:443"
        "81:81"
      ];
      volumes = [
        "/var/lib/nginx-proxy-manager/data:/data"
        "/var/lib/nginx-proxy-manager/letsencrypt:/etc/letsencrypt"
      ];
      extraOptions = [
        # Use the path to the decrypted secret file.
        "--volume=${config.sops.secrets.API_KEY.path}:/secrets/cloudflare_api_key:ro"
      ];
    };

    # Ensure the data directories exist.
    systemd.tmpfiles.rules = [
      "d /var/lib/nginx-proxy-manager 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/data 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/letsencrypt 0755 root root - -"
    ];
  };
}
