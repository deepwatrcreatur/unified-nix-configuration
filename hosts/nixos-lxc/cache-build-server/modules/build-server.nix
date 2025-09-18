{ config, lib, pkgs, ... }:

{
  # Build server optimizations
  nix.settings = {
    # Override common settings for build server use
    max-jobs = "auto";
    cores = 0; # Use all available cores
    
    # Build server optimizations
    builders-use-substitutes = true;
    substitute = true;
    trusted-users = [ "root" "@wheel" "nixbuilder" ];
    
    # Build cache settings
    keep-outputs = true;
    keep-derivations = true;
    
    # Increase timeout for large packages
    timeout = 7200; # 2 hours
    
    # Auto-push built packages to local cache
    post-build-hook = "/etc/nix/post-build-hook.sh";
  };
  
  # More aggressive garbage collection for build server
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d"; # Keep recent builds
  };

  # Binary cache serving
  services.nix-serve = {
    enable = true;
    port = 5000;
    bindAddress = "0.0.0.0";
    secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
  };

  # Add nginx reverse proxy for caching behavior
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    # Configure cache storage
    commonHttpConfig = ''
      proxy_cache_path /var/cache/nginx/nix-cache levels=1:2 keys_zone=nix_cache:10m max_size=10g inactive=7d use_temp_path=off;
      proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
      proxy_cache_lock on;
    '';

    upstreams = {
      "nix-serve-backend" = {
        servers = {
          "127.0.0.1:5000" = {};
        };
      };
      "nixos-cache" = {
        servers = {
          "cache.nixos.org:443" = {};
        };
      };
    };

    virtualHosts."cache-server" = {
      listen = [ { addr = "0.0.0.0"; port = 8080; } ];
      locations = {
        # Try local nix-serve first, then fallback to upstream
        "/" = {
          proxyPass = "http://nix-serve-backend";
          extraConfig = ''
            proxy_cache nix_cache;
            proxy_cache_valid 200 1d;
            proxy_cache_valid 404 5m;
            add_header X-Cache-Status $upstream_cache_status;

            # If local cache returns 404, try upstream
            error_page 404 = @upstream_fallback;
          '';
        };

        "@upstream_fallback" = {
          proxyPass = "https://cache.nixos.org";
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_set_header Host cache.nixos.org;
            proxy_cache nix_cache;
            proxy_cache_valid 200 1d;
            proxy_cache_valid 404 5m;
            add_header X-Cache-Status "UPSTREAM-$upstream_cache_status";

            # Store successful responses for future requests
            proxy_store on;
            proxy_store_access user:rw group:rw all:r;
          '';
        };
      };
    };
  };

  # Generate signing keys for nix-serve
  systemd.services.nix-serve-keys = {
    description = "Generate Nix cache signing keys";
    wantedBy = [ "multi-user.target" ];
    before = [ "nix-serve.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "nix-serve";
      Group = "nix-serve";
    };
    script = ''
      mkdir -p /var/lib/nix-serve
      if [[ ! -f /var/lib/nix-serve/cache-priv-key.pem ]]; then
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key cache.local /var/lib/nix-serve/cache-priv-key.pem /var/lib/nix-serve/cache-pub-key.pem
        chown nix-serve:nix-serve /var/lib/nix-serve/cache-*.pem
        chmod 600 /var/lib/nix-serve/cache-priv-key.pem
        chmod 644 /var/lib/nix-serve/cache-pub-key.pem
        echo "Generated cache signing keys. Public key:"
        cat /var/lib/nix-serve/cache-pub-key.pem
      fi
    '';
  };

  # SSH for remote builds
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  # Firewall - SSH, nix-serve, and nginx cache proxy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 5000 8080 ];
  };

  # System monitoring for build server
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    MaxRetentionSec=1month
  '';

  # Post-build hook to automatically push built packages to cache
  environment.etc."nix/post-build-hook.sh" = {
    text = ''
      #!/bin/sh
      set -eu
      set -f # disable globbing
      export IFS=' '

      echo "Uploading paths" $OUT_PATHS
      exec nix copy --to "http://localhost:5000" $OUT_PATHS
    '';
    mode = "0755";
  };
}
