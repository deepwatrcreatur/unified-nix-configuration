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
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
    config.cudaForwardCompat = false; # Skip cuda_compat build
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

    # Ollama configuration - GPU support temporarily disabled due to CUDA compat build issues
    # TODO: Re-enable CUDA GPU inference once nixpkgs cuda_compat build is fixed
    ollama = {
      enable = true;
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
      };
    };
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
