# /etc/nixos/modules/services/caddy.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.caddy-proxy;
  # This gets the path to the decrypted file containing our Caddy secret.
  caddyEnvFile = config.sops.secrets.caddy_cloudflare_token.path;
in
{
  options.services.caddy-proxy = {
    enable = lib.mkEnableOption "Enable the Caddy Reverse Proxy";
  };

  config = lib.mkIf cfg.enable {

    # Define the new secret for Caddy.
    sops.secrets.caddy_cloudflare_token = {
      # Point it to the new encrypted file.
      # The path is relative to the location of your flake.nix, which is /etc/nixos/
      sopsFile = ./secrets/caddy-cloudflare.yaml;
      # The format is now 'dotenv' which sops-nix understands.
      # It will convert the YAML into a KEY=VALUE file.
      format = "dotenv";
    };

    virtualisation.oci-containers.containers.caddy = {
      image = "caddy-with-cloudflare"; # The name of our custom-built image
      build = {
        # The directory containing the Dockerfile for our custom build
        context = /var/lib/caddy-build;
      };
      autoStart = true;
      ports = [ "80:80" "443:443" ];
      volumes = [
        "/var/lib/caddy/Caddyfile:/etc/caddy/Caddyfile"
        "/var/lib/caddy/data:/data"
      ];
      # Use extraOptions to pass the decrypted .env file to the container.
      # This is the most reliable method for podman.
      extraOptions = [ "--env-file=${caddyEnvFile}" ];
    };

    # This block uses systemd-tmpfiles to create all necessary files and
    # directories for the Caddy service before it starts.
    systemd.tmpfiles.rules = [
      # Create directories for Caddy's data and config
      "d /var/lib/caddy 0755 root root - -"
      "d /var/lib/caddy/data 0755 root root - -"
      
      # Create the Caddyfile with the correct configuration
      "f /var/lib/caddy/Caddyfile 0644 root root - \"glucose.deepwatercreature.com {\n\treverse_proxy 10.10.11.77:1337\n\ttls {\n\t\tdns cloudflare {env.CLOUDFLARE_API_TOKEN}\n\t}\n}\""
      
      # Create the build directory for our custom Dockerfile
      "d /var/lib/caddy-build 0755 root root - -"
      
      # Create the Dockerfile to build Caddy with the Cloudflare plugin
      "f /var/lib/caddy-build/Dockerfile 0644 root root - \"FROM caddy:2.8.4-builder AS builder\nRUN xcaddy build --with github.com/caddyserver/dns.cloudflare\nFROM caddy:2.8.4\nCOPY --from=builder /usr/bin/caddy /usr/bin/caddy\""
    ];
  };
}
