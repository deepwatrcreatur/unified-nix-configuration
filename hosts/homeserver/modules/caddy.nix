# /etc/nixos/modules/services/caddy.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.caddy-proxy;
  caddyEnvFile = config.sops.secrets.caddy_cloudflare_token.path;

  # This defines the custom Caddy image with the Cloudflare plugin.
  # Nix will build this image and make it available.
  caddyWithCloudflareImage = pkgs.oci-container.build {
    fromImage = pkgs.oci-container.build {
      fromImage = pkgs.fetchDocker {
        imageName = "caddy";
        imageTag = "2.8.4-builder";
      };
      cmd = [
        "xcaddy"
        "build"
        "--with"
        "github.com/caddyserver/dns.cloudflare"
      ];
    };
    copyToRoot = [
      {
        from = "/usr/bin/caddy";
        to = "/usr/bin/caddy";
      }
    ];
    fromImageName = "caddy";
    fromImageTag = "2.8.4";
  };
in
{
  options.services.caddy-proxy = {
    enable = lib.mkEnableOption "Enable the Caddy Reverse Proxy";
  };

  config = lib.mkIf cfg.enable {

    sops.secrets.caddy_cloudflare_token = {
      sopsFile = ../../secrets/caddy-cloudflare.yaml;
      format = "dotenv";
    };

    virtualisation.oci-containers.containers.caddy = {
      # Use the image we defined above.
      imageFile = caddyWithCloudflareImage;
      autoStart = true;
      ports = [ "80:80" "443:443" ];
      volumes = [
        "/var/lib/caddy/Caddyfile:/etc/caddy/Caddyfile"
        "/var/lib/caddy/data:/data"
      ];
      extraOptions = [ "--env-file=${caddyEnvFile}" ];
    };

    # We only need to create the Caddyfile and data directories now.
    # The image build is handled by the 'imageFile' attribute.
    systemd.tmpfiles.rules = [
      "d /var/lib/caddy 0755 root root - -"
      "d /var/lib/caddy/data 0755 root root - -"
      "f /var/lib/caddy/Caddyfile 0644 root root - \"glucose.deepwatercreature.com {\n\treverse_proxy 10.10.11.77:1337\n\ttls {\n\t\tdns cloudflare {env.CLOUDFLARE_API_TOKEN}\n\t}\n}\""
    ];
  };
}
