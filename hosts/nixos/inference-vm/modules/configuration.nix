{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/common/nix-settings.nix
    ../../../../modules/nixos/inference-vm-nix-overrides.nix

    # Defines `myModules.attic-client` used by inference hosts
    ../../../../modules/nixos/attic-client.nix

    # Attic post-build hook module
    ../../../../modules/nixos/attic-post-build-hook.nix
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  sops.age.keyFile = lib.mkForce "/var/lib/sops/age/keys.txt";

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
    config.cudaForwardCompat = false; # Skip cuda_compat build
  };

  myModules.attic-client = {
    enable = true;

    # SOPS-encrypted token providing `ATTIC_CLIENT_JWT_TOKEN`
    tokenFile = ../../../../secrets/attic-client-token.yaml.enc;

    server = "http://cache-build-server:5001";
    cache = "cache-local";
  };

  services.attic-post-build-hook = {
    enable = true;

    serverName = "cache-build-server";
    serverEndpoint = "http://cache-build-server:5001";
    cacheName = "cache-local";

    tokenFile = "/run/secrets/attic-client-token";
  };

  # GPU Infrastructure configuration - Tesla P40 optimized
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Disable for Tesla P40 stability
    open = false; # Use proprietary driver
  };
  hardware.graphics.enable = true;

  # Add OpenWebUI package for web interface to Ollama
  environment.systemPackages = with pkgs; [
    open-webui # Web interface for Ollama
  ];

  # Base VM configuration for inference machines and services
  services = {
    # Enable QEMU Guest Agent for better VM management
    qemuGuest.enable = true;
    openssh.enable = true;
    netdata.enable = true;
    tailscale.enable = true;

    # Ollama disabled in base config - configured per-host
    # (e.g., inference1 uses custom build with official binaries)
  };

  # Boot loader configuration for UEFI with systemd-boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Time zone
  time.timeZone = "America/Toronto";

  # Locale settings
  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
  };

  # Enable console login
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05";
  services.xserver.videoDrivers = [ "nvidia" ];
}
