# /etc/nixos/modules/services/npm.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.npm-proxy;
  # Path to the environment file containing the Cloudflare token
  npmEnvFile = config.sops.secrets.npm_cloudflare_token.path;
in
{
  options.services.npm-proxy = {
    enable = lib.mkEnableOption "Enable Nginx Proxy Manager";
  };

  config = lib.mkIf cfg.enable {
    # 1. Configure sops-nix to decrypt your secret
    #    This secret will be placed in a file and passed to NPM.
    sops.secrets.npm_cloudflare_token = {
      sopsFile = ../../secrets/npm-cloudflare.yaml;
      format = "dotenv";
    };

    # 2. Enable and configure the Nginx Proxy Manager service
    services.nginx-proxy-manager = {
      enable = true;
      # The module handles opening ports 80 and 443 automatically.
      # It also opens port 81 for the admin interface.
      #
      # We pass the decrypted secrets file to the service.
      # NPM will read this file for environment variables.
      environmentFile = npmEnvFile;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 81 ];
  };
}
