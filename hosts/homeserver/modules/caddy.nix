# ./modules/nixos/services/caddy.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.caddy-proxy;
  # This assumes your secret is named 'API_KEY' in your sops file.
  cloudflareApiKeyFile = config.sops.secrets.API_KEY.path;
in
{
  options.services.caddy-proxy = {
    enable = lib.mkEnableOption "Enable the Caddy Reverse Proxy";
  };

  config = lib.mkIf cfg.enable {

    sops.secrets.API_KEY = {
      sopsFile = ../../secrets/cloudflare-secrets.yaml; # Adjust path if needed
    };

    # This defines the Caddy container.
    virtualisation.oci-containers.containers.caddy = {
      # We will build our own Caddy with the Cloudflare plugin.
      # This is the most reliable method.
      image = "caddy-with-cloudflare"; # A custom name for our local image
      build = {
        # The context is the directory containing the Dockerfile.
        # We will create this file next.
        context = /var/lib/caddy-build;
      };
      autoStart = true;
      ports = [ "80:80" "443:443" ];
      volumes = [
        # Mount the Caddyfile and data directories.
        "/var/lib/caddy/Caddyfile:/etc/caddy/Caddyfile"
        "/var/lib/caddy/data:/data"
      ];
    };

    # This creates the build directory and the Caddyfile on the host.
    systemd.tmpfiles.rules = [
      "d /var/lib/caddy 0755 root root - -"
      "d /var/lib/caddy/data 0755 root root - -"
      "f /var/lib/caddy/Caddyfile 0644 root root - \"nightscout.deepwatercreature.com {\n\treverse_proxy 10.10.11.77:1337\n\ttls {\n\t\tdns cloudflare {env.CLOUDFLARE_API_TOKEN}\n\t}\n}\""
      "d /var/lib/caddy-build 0755 root root - -"
      "f /var/lib/caddy-build/Dockerfile 0644 root root - \"FROM caddy:2.8.4-builder AS builder\nRUN xcaddy build --with github.com/caddyserver/dns.cloudflare\nFROM caddy:2.8.4\nCOPY --from=builder /usr/bin/caddy /usr/bin/caddy\""
    ];

    # This passes the decrypted API key as an environment variable to the container.
    # This is a workaround for a bug where extraOptions might not work as expected.
    environment.sops.secrets.CLOUDFLARE_API_TOKEN = {
      path = cloudflareApiKeyFile;
    };
    systemd.services.podman-caddy.serviceConfig.EnvironmentFile = config.environment.sops.secrets.CLOUDFLARE_API_TOKEN.path;
  };
}
