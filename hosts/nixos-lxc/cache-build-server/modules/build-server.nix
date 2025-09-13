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
    secretKeyFile = "/etc/nix/cache-signing-key.sec";
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
}
