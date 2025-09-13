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

  # Firewall - SSH and nix-serve
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 5000 ];
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
