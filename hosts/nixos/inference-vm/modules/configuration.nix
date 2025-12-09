{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/common/nix-settings.nix
  ];

  # Custom overlay to rebuild Ollama with Tesla P40 support (CUDA compute capability 6.1)
  nixpkgs.overlays = [
    (final: prev: {
      ollama = prev.ollama.overrideAttrs (old: {
        # Enable broader CUDA architecture support including Pascal (6.1) for Tesla P40
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DGGML_CUDA_ARCHITECTURES=61;70;75;80;86;89;90"
        ];

        # Ensure CUDA support is properly enabled with additional dependencies
        buildInputs = (old.buildInputs or [ ]) ++ [
          prev.cudaPackages.cuda_nvcc
          prev.cudaPackages.cuda_cudart
          prev.cudaPackages.libcublas
          prev.cudaPackages.libcusparse
          prev.cudaPackages.libcurand
        ];

        # Set specific CMake variables for CUDA compilation in preConfigure
        preConfigure = (old.preConfigure or "") + ''
          export CUDA_PATH=${prev.cudaPackages.cudatoolkit}
          export CUDACXX=${prev.cudaPackages.cuda_nvcc}/bin/nvcc
        '';
      });
    })
  ];

  # Base VM configuration for inference machines
  # Enable QEMU Guest Agent for better VM management
  services.qemuGuest.enable = true;

  # Boot loader configuration for UEFI with systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.enable = false;
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

  # Enable essential services
  services.openssh.enable = true;
  services.netdata.enable = true;
  services.tailscale.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.cudaPackages = pkgs.cudaPackages_12_6;

  # NVIDIA driver support
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Use proprietary driver
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Add NVIDIA utilities to system packages
  environment.systemPackages = with pkgs; [
    # nvidia-smi comes with driver
  ];

  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05";
}
