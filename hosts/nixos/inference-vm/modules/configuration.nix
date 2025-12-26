{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/common/nix-settings.nix
    ./gpu-infrastructure.nix
    ./ollama.nix
    ./llama-cpp.nix
  ];

  # Nixpkgs configuration
  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true; # Allow unsupported packages like cuDNN
  };

  # GPU Infrastructure configuration
  # TODO: Re-enable after base system is stable
  inference.gpu = {
    enable = false; # Temporarily disabled
    nvidia.enable = false;
    cuda = {
      enable = false;
      enableTeslaP40 = false; # Will enable after base system works
    };
    monitoring.enable = false;
  };

  # Ollama configuration (depends on GPU infrastructure)
  # TODO: Re-enable after base system is stable
  inference.ollama = {
    enable = false; # Temporarily disabled
    customBuild = {
      enable = false;
      # cudaArchitectures will include Tesla P40 (6.1) when gpu.cuda.enableTeslaP40 = true
    };
  };

  # llama.cpp configuration (alternative/complementary to Ollama)
  # TODO: Re-enable after base system is stable
  inference.llama-cpp = {
    enable = false; # Temporarily disabled
    server.enable = false;
    customBuild = {
      enable = false;
      cudaSupport = false; # Will be enabled when GPU infrastructure is enabled
    };
  };

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

  system.stateVersion = "25.11";
}
