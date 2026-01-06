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

    # Ollama configuration with Tesla P40 CUDA support
    # Using official binaries to avoid cuda_compat build error
    ollama = {
      enable = true;
      package = pkgs.ollama-official-binaries;  # From tesla-inference-flake overlay
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
        OLLAMA_GPU_OVERHEAD = "0";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";  # For bundled CUDA libraries
      };
    };
  };

  # Clean up ollama state directory issues from failed GPU builds
  systemd.tmpfiles.rules = [
    "R  /var/lib/ollama - - - - -"
  ];

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
