{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../../../modules/common/nix-settings.nix
    ../../../../modules/nixos/inference-vm-nix-overrides.nix
    inputs.tesla-inference-flake.nixosModules.tesla-inference
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
  };

  # GPU Infrastructure configuration - Tesla P40 optimized
  tesla-inference = {
    enable = true;
    gpu = "P40"; # Optimize for Tesla P40 (compute 6.1)

    # Ollama service configuration
    ollama = {
      enable = true;
      port = 11434;
      host = "0.0.0.0"; # Listen on all interfaces for VM accessibility
      modelsPath = "/var/lib/ollama"; # Working directory for ollama service
    };

    # GPU monitoring (disabled due to missing gpu-monitoring-tools package)
    monitoring.enable = false;
  };

  # Override ollama service to fix directory permissions
  # The tesla-inference-flake uses DynamicUser=true which creates issues with /var/lib/private/ollama
  systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;
  systemd.services.ollama.serviceConfig.User = "root";
  systemd.services.ollama.serviceConfig.Group = "root";

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
  };

  # Boot loader configuration for UEFI with systemd-boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      limine.enable = false;
    };
  };
  # Remove nomodeset to enable GPU drivers
  # boot.kernelParams = [ "nomodeset" "vga=795" ];
  # Remove ceph module since ceph is not currently configured
  # boot.kernelModules = [ "ceph" ];

  # Time zone
  time.timeZone = "America/Toronto";

  # Locale settings
  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
  };

  # Disable X11 and GNOME for headless inference server
  # services.xserver.enable = true;
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap (not needed without X11)
  # services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # Enable console login (remove GNOME autologin workaround)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05"; # Match current working generation
}
