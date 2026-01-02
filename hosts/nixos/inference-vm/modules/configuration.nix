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
    inputs.tesla-inference-flake.nixosModules.gpu-infrastructure
    inputs.tesla-inference-flake.nixosModules.ollama
    inputs.tesla-inference-flake.nixosModules.llama-cpp
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false; # Disable for Tesla P40 stability
      useOpenDriver = false; # Use proprietary driver
    };
    cuda = {
      enable = true;
      architectures = [ "61" "70" "75" "80" "86" "89" "90" ]; # Include Tesla P40 (6.1)
    };
    monitoring.enable = true;
  };

  # Ollama configuration with Tesla P40 CUDA support
  inference.ollama = {
    enable = true;
    acceleration = "cuda"; # Explicitly use CUDA for GPU acceleration
    customBuild = {
      enable = true;
      cudaArchitectures = [ "61" "70" "75" "80" "86" "89" "90" ]; # Include Tesla P40
    };
  };

  # llama.cpp configuration (alternative/complementary to Ollama)
  inference.llama-cpp = {
    enable = false; # Keep disabled until testing shows it's needed
    server.enable = false;
    acceleration = "cuda";
  };

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
