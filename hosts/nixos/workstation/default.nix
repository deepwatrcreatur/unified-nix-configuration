{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../../modules/nixos/common # Common NixOS modules (SSH keys, etc.)
    ../../../modules/common/utility-packages.nix # Common utility packages
    inputs.nix-attic-infra.nixosModules.attic-client # Attic cache client
    ../../../modules/nixos/snap.nix # Snap package manager support
    #../../../modules/nixos/sessions/cinnamon.nix # MATE with WhiteSur theming

    # Desktop environment - choose one:
    # COSMIC: Clean GNOME-based, excellent Activities, no app badges
    ../../../modules/nixos/sessions/cosmic.nix
    # KDE Plasma (testing): Powerful, app badges in system tray, Super+Space launcher, Desktop Grid
    #../../../modules/nixos/sessions/whitesur-themed-kde.nix

    ../../../modules/nixos/keyboard-glitches.nix # Fix for stuck keyboard presses in Proxmox VM
    ../../../modules/wezterm-config.nix
    ../../../modules/activation-scripts # Activation scripts for system setup
  ];

  # Homebrew is managed via home-manager (modules/home-manager/linuxbrew.nix)
  # Symlink nice to /usr/bin for Homebrew's Ruby (needed by some formulae like bd)
  system.activationScripts.homebrewCompat = ''
    mkdir -p /usr/bin
    ln -sf ${pkgs.coreutils}/bin/nice /usr/bin/nice
  '';

  # Linux-specific wezterm configuration
  programs.wezterm.extraConfig = lib.mkAfter ''
    -- Default program: launch zellij with nushell as default shell (Linux path)
    config.default_prog = { '/etc/profiles/per-user/deepwatrcreatur/bin/zellij', '-l', 'welcome' }
  '';

  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.limine.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.bootspec.enable = true;
  boot.growPartition = true;
  boot.loader.timeout = 7; # Increased from default 5 seconds for easier generation selection
  boot.loader.systemd-boot.consoleMode = "auto"; # Auto-detect optimal resolution for smaller font

  # Load AMD GPU driver
  boot.kernelModules = [ "amdgpu" ];

  # Enable AMD GPU firmware
  hardware.enableRedistributableFirmware = true;

  # NVIDIA driver configuration for version >= 560
  hardware.nvidia.open = false;

  # Configure keyboard - let input-leap handle caps lock synchronization
  # services.xserver.xkb.options = "caps:none"; # Disabled - using input-leap fix instead

  # X11 with AMD GPU passthrough
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb.options = "caps:none"; # Let input-leap handle caps lock synchronization
  };
  hardware.opengl.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Disable screen readers (Orca and Speech Dispatcher)
  services.orca.enable = false;
  services.speechd.enable = false;

  # Enable SSH daemon
  services.openssh.enable = true;

  # Disable screen lock
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  security.sudo.wheelNeedsPassword = false;

  # Define your user account (SSH keys managed by common/ssh-keys.nix)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "lp"
    ];
    shell = pkgs.fish;
  };

  # Configure automatic login for deepwatrcreatur user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  # Enable printing
  services.printing.enable = true;

  home-manager.users.deepwatrcreatur = {
    imports = [
      inputs.nix-whitesur-config.homeManagerModules.default
      ../../../users/deepwatrcreatur/hosts/workstation
    ];
  };

  # Additional system packages (utility-packages provides: git, vim, curl, wget, rsync, nmap, openssl, etc.)
  environment.systemPackages = with pkgs; [
    at-spi2-core # Accessibility framework for deskflow clipboard
    distrobox
    filezilla
    nushell # Stopgap: Add nushell at system level for ghostty compatibility
    nvtopPackages.amd # GPU monitoring tool for AMD GPUs
    pavucontrol
    rclone-browser
    remmina # Remote desktop client for VNC, RDP, and other protocols
    realvnc-vnc-viewer # RealVNC VNC Viewer for connecting to macOS screen sharing
    usbutils
    vscode.fhs # VSCode with FHS environment
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    xdg-desktop-portal-gtk # GTK desktop portal
  ];

  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;

  # Enable Podman for distrobox
  virtualisation.podman.enable = true;

  # Enable QEMU guest agent for Proxmox integration
  services.qemuGuest.enable = true;

  # Attic cache client (cache pulls + token provisioning)
  services.attic-client = {
    enable = true;
    tokenFile = ../../../secrets/attic-client-token.yaml.enc;
    server = "http://cache-build-server:5001";
    cache = "cache-local";

    enablePostBuildHook = false;
  };

  # Enable snap support
  myModules.snap = {
    enable = true;
    classicPackages = [ "icloud-for-linux" ];
  };

  # Enable fixes for stuck keyboard presses in Proxmox VM
  myModules.keyboardGlitches.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
