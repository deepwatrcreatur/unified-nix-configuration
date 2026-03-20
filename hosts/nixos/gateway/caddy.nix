{ config, pkgs, lib, ... }:

let
  # Optional secrets library for graceful degradation
  optSec = import ../../../modules/helpers/optional-secrets.nix { inherit lib; };

  # Check if cloudflare secret exists (defined in default.nix, checked here for preStart logic)
  cfSecret = optSec.mkSecret "cloudflare-api-key" {
    file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
  };
in
{
  services.caddy = {
    enable = true;
    email = "deepwatrcreatur@gmail.com";
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.3"
        "github.com/mholt/caddy-dynamicdns@v0.0.0-20251231002810-1af4f8876598"
      ];
      hash = "sha256-cx7C7x9PG0RQh5ZaXIi2pDIiC2d3kdgBPE4SMApCY5o=";
    };
    environmentFile = "/run/caddy/caddy.env";
    
    # Global Caddy configuration
    globalConfig = ''
      # ACME/Let's Encrypt configuration
      email deepwatrcreatur@gmail.com
      dynamic_dns {
        provider cloudflare {$CLOUDFLARE_API_TOKEN}
        domains {
          # `home-assistant` is intentionally excluded here. We publish it as a
          # Cloudflare CNAME to another DDNS-managed hostname so Caddy's DDNS
          # updater does not fight Cloudflare over the same record name.
          deepwatercreature.com @ homelab 2fauth nightscout marreta linkwarden
        }
        check_interval 5m
        versions ipv4 ipv6
        ttl 1h
      }
      
      # Use staging for testing, comment out for production
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    '';
    
    virtualHosts = {
      # Main domain - redirect to www or dashboard
      "deepwatercreature.com" = {
        extraConfig = ''
          redir https://x.com/deepwatrcreatur permanent
        '';
      };
      
      # WWW subdomain - serve main site or redirect to dashboard
      "www.deepwatercreature.com" = {
        extraConfig = ''
          redir https://x.com/deepwatrcreatur permanent
        '';
      };
      
      # Router dashboard
      "dashboard.deepwatercreature.com" = {
        extraConfig = ''
          reverse_proxy 10.10.10.1:8888
        '';
      };

      "homelab.deepwatercreature.com" = {
        extraConfig = ''
          @trusted remote_ip 10.10.0.0/16 100.64.0.0/10
          handle @trusted {
            reverse_proxy 10.10.10.1:8888
          }

          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "home-assistant.deepwatercreature.com" = {
        extraConfig = ''
          reverse_proxy 10.10.11.18:8123
        '';
      };
      
      # Grafana monitoring
      "grafana.deepwatercreature.com" = {
        extraConfig = ''
          reverse_proxy 10.10.10.1:3001
        '';
      };
      
      # Prometheus metrics (optional - can be removed if not needed externally)
      # Uncomment if you want external access
      # "prometheus.deepwatercreature.com" = {
      #   extraConfig = ''
      #     reverse_proxy 10.10.10.1:9090
      #     
      #     # Add basic auth for security
      #     basicauth {
      #       admin $2a$14$...  # Generate with: caddy hash-password
      #     }
      #   '';
      # };
      
      # Technitium DNS admin (optional)
      # "dns.deepwatercreature.com" = {
      #   extraConfig = ''
      #     reverse_proxy 10.10.10.1:5380
      #   '';
      # };
    };
  };
  
  # Open firewall for Caddy
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
  };
  
  # Ensure Caddy can access the services and prepare its dynamic DNS token
  systemd.services.caddy = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    preStart = ''
      install -d -m 0750 -o caddy -g caddy /run/caddy
      ${lib.optionalString cfSecret.exists ''
        token="$(tr -d '\n' < ${config.age.secrets.cloudflare-api-key.path})"
        test -n "$token"
        printf 'CLOUDFLARE_API_TOKEN=%s\n' "$token" > /run/caddy/caddy.env
        chown caddy:caddy /run/caddy/caddy.env
        chmod 0400 /run/caddy/caddy.env
      ''}
      ${lib.optionalString (!cfSecret.exists) ''
        # No Cloudflare secret available - create empty env file
        touch /run/caddy/caddy.env
        chown caddy:caddy /run/caddy/caddy.env
        chmod 0400 /run/caddy/caddy.env
      ''}
    '';
    serviceConfig = {
      # The preStart script creates this file, so it must be optional at the
      # unit level or systemd will fail before preStart gets a chance to run.
      EnvironmentFile = lib.mkForce [ "-/run/caddy/caddy.env" ];
      PermissionsStartOnly = true;
    };
  };
}
