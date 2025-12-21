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
    ../../../modules/nixos/attic-client.nix # Attic cache client
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/wezterm-config.nix
    ../../../modules/activation-scripts # Activation scripts for system setup
    # Desktop Environment - choose one option:
    # Option 1: Multi-DE (test multiple DEs without rebuilding - switch at login screen)
    # ../../../modules/nixos/sessions/multi-de.nix
    # Option 2: Single DE (uncomment one, comment out multi-de.nix above)
    # ../../../modules/nixos/sessions/garuda-themed-kde.nix
    # ../../../modules/nixos/sessions/garuda-themed-gnome.nix # GNOME with X11 for deskflow compatibility
    # ../../../modules/nixos/sessions/x11-session-support.nix # Force X11 for deskflow compatibility
    # ../../../modules/nixos/sessions/kde-x11.nix # KDE with X11 for deskflow compatibility
    # ../../../modules/nixos/sessions/cosmic.nix # COSMIC desktop environment (no InputCapture portal yet)
    # ../../../modules/nixos/sessions/xfce.nix
    ../../../modules/nixos/sessions/cinnamon.nix
    # ../../../modules/nixos/sessions/mate.nix
    # ../../../modules/nixos/sessions/lxde.nix
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
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable AMD GPU firmware
  hardware.enableRedistributableFirmware = true;

  # Configure keyboard - let input-leap handle caps lock synchronization
  # services.xserver.xkb.options = "caps:none"; # Disabled - using input-leap fix instead

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

  # Enable printing
  services.printing.enable = true;

  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../users/deepwatrcreatur/hosts/workstation
    ];
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    at-spi2-core # Accessibility framework for deskflow clipboard
    filezilla
    git
    nushell # Stopgap: Add nushell at system level for ghostty compatibility
    nvtopPackages.amd # GPU monitoring tool for AMD GPUs
    pavucontrol
    rclone-browser
    usbutils
    vim
    vscode.fhs # VSCode with FHS environment
    inputs.zen-browser.packages.${pkgs.system}.default
  ];

  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;
  myModules.attic-client = {
    enable = true; # Robust post-build hook that never fails builds
    tokenFile = ../../../secrets/attic-client-token.yaml.enc; # Use global token file
  };

  # Enable snap support
  myModules.snap = {
    enable = true;
    packages = [ "icloud-for-linux" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
