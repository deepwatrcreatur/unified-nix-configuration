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
    ./gpu-infrastructure.nix
    ./ollama.nix
    ./llama-cpp.nix
  ];

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
  };

  # GPU Infrastructure configuration - Tesla P40 optimized
  inference.gpu = {
    enable = true;
    nvidia = {
      enable = true;
      powerManagement = {
        enable = false; # Disable power management for Tesla P40 stability
        finegrained = false;
      };
      useOpenDriver = false; # Use proprietary driver for Tesla P40
    };
    cuda = {
      enable = true;
      enableTeslaP40 = true; # Enable Tesla P40 specific optimizations
      package = config.boot.kernelPackages.nvidiaPackages.production; # Use production driver
    };
    monitoring.enable = true; # Enable GPU monitoring
  };

  # Ollama configuration with Tesla P40 CUDA support
  inference.ollama = {
    enable = true;
    acceleration = "cuda"; # Explicitly enable CUDA acceleration
    customBuild = {
      enable = true;
      # Tesla P40 compute capability 6.1 included in default architectures
    };
  };

  # llama.cpp configuration (alternative/complementary to Ollama)
  inference.llama-cpp = {
    enable = false; # Keep disabled until GPU infrastructure is ready
    server.enable = false;
    customBuild = {
      enable = false;
      cudaSupport = false; # Will be enabled when GPU infrastructure is enabled
    };
  };


  # Add OpenWebUI package for web interface to Ollama
  environment.systemPackages = with pkgs; [
    open-webui # Web interface for Ollama
  ];

  # Base VM configuration for inference machines
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

  # GPU/NVIDIA configuration moved to gpu-infrastructure.nix module

  security.sudo.wheelNeedsPassword = false;

  # Enable fish shell for users
  programs.fish.enable = true;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05"; # Match current working generation
}
