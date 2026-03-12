{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    email = "deepwatrcreatur@gmail.com";
    
    # Global Caddy configuration
    globalConfig = ''
      # ACME/Let's Encrypt configuration
      email deepwatrcreatur@gmail.com
      
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
}
