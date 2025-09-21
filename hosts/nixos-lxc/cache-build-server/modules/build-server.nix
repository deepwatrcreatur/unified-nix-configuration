{ config, lib, pkgs, ... }:

{
  # Enable the centralized Attic client module for this host
  myModules.attic-client.enable = true;

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

    # Environment file for server token (required)
    environmentFile = "/var/lib/atticd/env";

    # Server configuration
    settings = {
      listen = "[::]:5001";
      # allowed-hosts = [ "localhost" "127.0.0.1" "*.deepwatercreature.com" "10.10.*" ];  # Disabled to allow all hosts
      api-endpoint = "http://localhost:5001/";

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

  # Generate Attic server token and setup client config with SOPS-managed token
  systemd.services.attic-token-setup = {
    description = "Setup Attic server token and client configuration";
    wantedBy = [ "multi-user.target" ];
    before = [ "atticd.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/atticd

      # Generate server token if it doesn't exist
      if [[ ! -f /var/lib/atticd/env ]]; then
        echo "Generating Attic server token..."
        server_token=$(${pkgs.openssl}/bin/openssl genrsa -traditional 2048 | ${pkgs.coreutils}/bin/base64 -w0)
        echo "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=\"$server_token\"" > /var/lib/atticd/env
        chmod 600 /var/lib/atticd/env
        echo "Attic server token generated"
      fi

      echo "Attic token setup completed - client authentication will use SOPS-managed token"
    '';
  };

  # Initialize Attic cache and configure upstream
  systemd.services.attic-init = {
    description = "Initialize Attic cache";
    wantedBy = [ "multi-user.target" ];
    after = [ "atticd.service" "attic-client-config.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for atticd to be ready
      sleep 15

      # Use the client configuration with SOPS token
      export ATTIC_CONFIG="/etc/attic/config.toml"

      echo "Initializing Attic cache with SOPS-managed authentication..."

      # Check if SOPS token is available
      SOPS_TOKEN_PATH="/home/deepwatrcreatur/.config/sops/attic-client-token"
      if [[ -f "$SOPS_TOKEN_PATH" ]]; then
        ATTIC_TOKEN=$(cat "$SOPS_TOKEN_PATH")

        # Login using the SOPS-managed token
        if ${pkgs.attic-client}/bin/attic login local http://localhost:5001 "$ATTIC_TOKEN" --set-default; then
          echo "Successfully logged into Attic server"

          # Create cache if it doesn't exist
          if ! ${pkgs.attic-client}/bin/attic cache info cache-local 2>/dev/null; then
            echo "Creating cache-local..."
            if ${pkgs.attic-client}/bin/attic cache create cache-local; then
              echo "Cache cache-local created successfully"
            else
              echo "Failed to create cache-local"
            fi
          else
            echo "Cache cache-local already exists"
          fi

          # Configure upstream cache
          if ${pkgs.attic-client}/bin/attic cache configure cache-local \
              --upstream-cache-key-names cache.nixos.org-1 \
              --upstream-cache-uris https://cache.nixos.org; then
            echo "Cache upstream configuration successful"
          else
            echo "Cache upstream configuration failed"
          fi

          echo "Attic cache initialized successfully"
        else
          echo "Failed to login to Attic server - check authentication token"
          exit 1
        fi
      else
        echo "Warning: SOPS attic-client-token not found"
        echo "Skipping Attic cache initialization - configure secret first"
        exit 0
      fi
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
}
