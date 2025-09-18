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

  # Binary cache serving with nix-serve (legacy)
  services.nix-serve = {
    enable = true;
    port = 5000;
    bindAddress = "0.0.0.0";
    secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
  };

  # Attic binary cache server
  services.atticd = {
    enable = true;

    # Server configuration
    settings = {
      listen = "[::]:5001";
      allowed-hosts = [ "cache-build-server" ];
      api-endpoint = "http://cache-build-server:5001/";

      # Database
      database.url = "sqlite:///var/lib/atticd/server.db";

      # Storage
      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      # Enable compression
      compression.type = "zstd";

      # Garbage collection
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "7 days";
      };
    };
  };

  # Initialize Attic cache and configure upstream
  systemd.services.attic-init = {
    description = "Initialize Attic cache";
    wantedBy = [ "multi-user.target" ];
    after = [ "atticd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for atticd to be ready
      sleep 5

      # Create cache if it doesn't exist
      if ! ${pkgs.attic-client}/bin/attic cache info cache-local --server http://localhost:5001 2>/dev/null; then
        echo "Creating cache-local..."
        ${pkgs.attic-client}/bin/attic cache create cache-local --server http://localhost:5001
      fi

      # Configure as upstream cache for nixos.org
      ${pkgs.attic-client}/bin/attic cache configure cache-local \
        --upstream-cache-key-names cache.nixos.org-1 \
        --upstream-cache-uris https://cache.nixos.org \
        --server http://localhost:5001 || true

      echo "Attic cache initialized successfully"
    '';
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
        # Serve local cache with proper caching headers
        "/" = {
          proxyPass = "http://nix-serve-backend";
          extraConfig = ''
            proxy_cache nix_cache;
            proxy_cache_valid 200 1d;
            proxy_cache_valid 404 5m;
            add_header X-Cache-Status "LOCAL-$upstream_cache_status";
            add_header X-Cache-Source "nix-serve";
          '';
        };
      };
    };

    # Attic cache server proxy
    virtualHosts."attic-cache" = {
      listen = [ { addr = "0.0.0.0"; port = 8081; } ];
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:5001";
          extraConfig = ''
            proxy_cache nix_cache;
            proxy_cache_valid 200 1d;
            proxy_cache_valid 404 5m;
            add_header X-Cache-Status "ATTIC-$upstream_cache_status";
            add_header X-Cache-Source "attic";

            # Support for chunked uploads
            proxy_request_buffering off;
            client_max_body_size 2G;
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

  # Firewall - SSH, nix-serve, attic, and nginx cache proxies
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 5000 5001 8080 8081 ];
  };

  # System monitoring for build server
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    MaxRetentionSec=1month
  '';

  # Post-build hook to automatically push built packages to both caches
  environment.etc."nix/post-build-hook.sh" = {
    text = ''
      #!/bin/sh
      set -eu
      set -f # disable globbing
      export IFS=' '

      echo "Uploading paths to caches:" $OUT_PATHS

      # Upload to nix-serve (legacy)
      nix copy --to "http://localhost:5000" $OUT_PATHS || true

      # Upload to Attic
      ${pkgs.attic-client}/bin/attic push cache-local $OUT_PATHS --server http://localhost:5001 || true

      echo "Upload completed"
    '';
    mode = "0755";
  };
}
