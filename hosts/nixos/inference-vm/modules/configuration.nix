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
  ];

  # Note on GPU acceleration:
  # The tesla-inference-flake overlays require CUDA compilation which is broken in nixpkgs.
  # Ollama can still access GPUs at runtime if CUDA libraries are available.
  # Set CUDA_VISIBLE_DEVICES to allow ollama to detect available GPUs.

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
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

    # Ollama configuration with Tesla P40 support
    ollama = {
      enable = true;
      # Note: acceleration = "cuda" causes CUDA compilation which fails in nixpkgs
      # Instead, rely on CUDA libraries being available in the system and set CUDA_VISIBLE_DEVICES
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
        OLLAMA_CPU_ENABLED = "true"; # Enable CPU fallback when GPU unavailable
      };
    };
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

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05"; # Match current working generation
  services.xserver.videoDrivers = [ "nvidia" ];
}
