{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    email = "deepwatrcreatur@gmail.com";
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.3"
        "github.com/mholt/caddy-dynamicdns@1af4f88765982db86ce091eeb075cfb2d9348dc8"
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
          deepwatercreature.com @
          home.deepwatercreature.com @
          2fauth.deepwatercreature.com @
          nightscout.deepwatercreature.com @
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
          # Redirect to www subdomain
          redir https://www.deepwatercreature.com{uri} permanent
        '';
      };
      
      # WWW subdomain - serve main site or redirect to dashboard
      "www.deepwatercreature.com" = {
        extraConfig = ''
          # For now, redirect to dashboard
          # Replace with actual website later
          redir https://dashboard.deepwatercreature.com permanent
        '';
      };
      
      # Router dashboard
      "dashboard.deepwatercreature.com" = {
        extraConfig = ''
          reverse_proxy 10.10.10.1:8888
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
  
  # Ensure Caddy can access the services
  systemd.services.caddy = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.services.caddy-cloudflare-env = {
    description = "Prepare Cloudflare token environment for Caddy";
    wantedBy = [ "caddy.service" ];
    before = [ "caddy.service" ];
    after = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0750 -o caddy -g caddy /run/caddy
      printf 'CLOUDFLARE_API_TOKEN=%s\n' "$(cat ${config.age.secrets.cloudflare-api-key.path})" > /run/caddy/caddy.env
      chown caddy:caddy /run/caddy/caddy.env
      chmod 0400 /run/caddy/caddy.env
    '';
  };
}
