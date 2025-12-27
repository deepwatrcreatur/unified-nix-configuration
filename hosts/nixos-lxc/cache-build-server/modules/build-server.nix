{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Sops secret for attic server token
  sops.secrets."attic-server-token" = {
    sopsFile = ../../../../secrets/attic-server-token.yaml.enc;
    key = "ATTIC_SERVER_TOKEN";
    path = "/run/secrets/attic-server-token";
    owner = config.users.users.root.name;
  };

  sops.secrets."attic-jwt-secret" = {
    sopsFile = ../../../../secrets/attic-server-private-key.yaml.enc;
    key = "ATTIC_SERVER_PRIVATE_KEY_BASE64";
    path = "/run/secrets/attic-jwt-secret";
    owner = config.users.users.root.name;
  };

  # Create atticd environment file with JWT secret
  systemd.services.atticd-env = {
    description = "Create atticd environment file";
    wantedBy = [ "multi-user.target" ];
    before = [ "atticd.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Ensure the JWT secret is available
      SOPS_JWT_PATH="${config.sops.secrets."attic-jwt-secret".path}"
      if [[ ! -s "$SOPS_JWT_PATH" ]]; then
        echo "Error: SOPS attic-jwt-secret not found or is empty at $SOPS_JWT_PATH"
        exit 1
      fi

      # Create environment file with JWT secret
      # The secret is an RSA private key, so use RS256 (not HS256)
      JWT_SECRET=$(cat "$SOPS_JWT_PATH")
      echo "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$JWT_SECRET" > /etc/atticd.env
      chmod 600 /etc/atticd.env
      echo "Created atticd environment file with JWT secret (RS256)"
    '';
  };

  # Build server optimizations
  nix.settings = {
    # Override common settings for build server use
    max-jobs = "auto";
    cores = 0; # Use all available cores

    # Build server optimizations
    builders-use-substitutes = true;
    substitute = true;
    trusted-users = [
      "root"
      "@wheel"
      "nixbuilder"
    ];

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
    environmentFile = "/etc/atticd.env";

    # Server configuration
    settings = {
      listen = "[::]:5001";
      # allowed-hosts = [ "localhost" "127.0.0.1" "*.deepwatercreature.com" "10.10.*" ];  # Disabled to allow all hosts
      api-endpoint = "http://cache-build-server:5001/";

      # Database
      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";

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

  # Override atticd service to ensure correct api-endpoint
  systemd.services.atticd.serviceConfig.Environment = [
    "ATTIC_SERVER_API_ENDPOINT=http://cache-build-server:5001/"
  ];

  # Initialize Attic cache and configure upstream
  systemd.services.attic-init = {
    description = "Initialize Attic cache";
    wantedBy = [ "multi-user.target" ];
    after = [
      "atticd.service"
      "sops-nix.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10";
    };
    script = ''
      # Wait for atticd to be ready
      echo "Waiting for atticd to be ready..."
      for i in {1..60}; do
        if ${pkgs.curl}/bin/curl -s -f http://localhost:5001/; then
          echo "atticd is ready."
          break
        fi
        if [ $i -eq 60 ]; then
          echo "atticd failed to start after 60 seconds."
          exit 1
        fi
        sleep 1
      done

      # Use the client configuration
      export ATTIC_CONFIG="/etc/attic/config.toml"

      echo "Initializing Attic cache with SOPS-managed authentication..."

      # Check if SOPS token is available and not empty
      SOPS_TOKEN_PATH="${config.sops.secrets."attic-server-token".path}"
      if ! ${pkgs.coreutils}/bin/test -s "$SOPS_TOKEN_PATH"; then
        echo "Error: SOPS attic-server-token not found or is empty at $SOPS_TOKEN_PATH"
        echo "Cannot initialize Attic cache - configure secret first"
        exit 1
      fi

      ATTIC_TOKEN=$(${pkgs.coreutils}/bin/cat "$SOPS_TOKEN_PATH")

      # Login using the SOPS-managed token
      echo "Attempting to login to Attic server..."
      if ${pkgs.attic-client}/bin/attic login local http://cache-build-server:5001 "$ATTIC_TOKEN" --set-default; then
        echo "Successfully logged into Attic server"

        # Create cache if it doesn't exist
        if ! ${pkgs.attic-client}/bin/attic cache info cache-local 2>/dev/null; then
          echo "Creating cache-local..."
          if ${pkgs.attic-client}/bin/attic cache create cache-local; then
            echo "Cache cache-local created successfully"
          else
            echo "Failed to create cache-local - checking server status"
            ${pkgs.attic-client}/bin/attic server-info || echo "Cannot connect to server"
            exit 1
          fi
        else
          echo "Cache cache-local already exists"
        fi

        # Configure upstream cache key (for skipping already-signed paths)
        if ${pkgs.attic-client}/bin/attic cache configure cache-local \
            --upstream-cache-key-name cache.nixos.org-1; then
          echo "Cache upstream configuration successful"
        else
          echo "Cache upstream configuration failed (non-critical)"
        fi

        echo "Attic cache initialized successfully"
      else
        echo "Failed to login to Attic server - checking server status..."
        ${pkgs.curl}/bin/curl -v http://localhost:5001/ || echo "Server not reachable"
        echo "Token available: $(${pkgs.coreutils}/bin/test -n "$ATTIC_TOKEN" && echo "YES" || echo "NO")"
        exit 1
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
          "127.0.0.1:5000" = { };
        };
      };
      "nixos-cache" = {
        servers = {
          "cache.nixos.org:443" = { };
        };
      };
    };

    virtualHosts."cache-server" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8080;
        }
      ];
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
      listen = [
        {
          addr = "0.0.0.0";
          port = 8081;
        }
      ];
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

  # User and group for atticd
  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
  };

  users.groups.atticd = { };

  # User and group for nix-serve
  users.users.nix-serve = {
    isSystemUser = true;
    group = "nix-serve";
  };

  users.groups.nix-serve = { };

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
      StateDirectory = "nix-serve";
      RuntimeDirectory = "nix-serve";
    };
    script = ''
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
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      X11Forwarding = false;
    };
  };

  # Firewall - SSH, nix-serve, attic, and nginx cache proxies
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      5000
      5001
      8080
      8081
    ];
  };

  # System monitoring for build server
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    MaxRetentionSec=1month
  '';

  systemd.services."nix-serve" = {
    serviceConfig.StateDirectory = "nix-serve";
    serviceConfig.RuntimeDirectory = "nix-serve";
    serviceConfig.RuntimeDirectoryMode = "0755";
    serviceConfig.User = "nix-serve";
    serviceConfig.Group = "nix-serve";
  };

  # Let systemd StateDirectory handle all directory management

  systemd.tmpfiles.rules = [
    "d /etc/attic 0755 atticd atticd -"
  ];

  environment.etc."attic/config.toml" = {
    text = '''';
    user = "atticd";
    group = "atticd";
    mode = "0644";
  };
}
