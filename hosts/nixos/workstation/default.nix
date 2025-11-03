{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../../modules/nixos/common  # Common NixOS modules (SSH keys, etc.)
    ../../../modules/nixos/attic-client.nix  # Attic cache client
    ../../../modules/nixos/snap.nix  # Snap package manager support
    ../../../modules/wezterm-config.nix
    # Desktop Environment - uncomment one:
    # ../../../modules/nixos/garuda-themed-kde.nix
    ../../../modules/nixos/garuda-themed-gnome.nix
    ../../../modules/linux/linuxbrew-system.nix
  ];

  # Enable Homebrew
  programs.homebrew = {
    enable = true;
    brews = (import ../../../modules/common-brew-packages.nix).brews;
    casks = (import ../../../modules/common-brew-packages.nix).casks;
  };

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

  # Enable SSH daemon
  services.openssh.enable = true;

  # Disable screen lock
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  security.sudo.wheelNeedsPassword = false;
  
  # Define your user account (SSH keys managed by common/ssh-keys.nix)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  home-manager.backupFileExtension = "backup";
  
  home-manager.users.deepwatrcreatur = {
    imports = [ 
      ../../../users/deepwatrcreatur/hosts/workstation
    ];
  };


  # Additional system packages
  environment.systemPackages = with pkgs; [
    filezilla
    git
    nushell  # Stopgap: Add nushell at system level for ghostty compatibility
    nvtopPackages.amd  # GPU monitoring tool for AMD GPUs
    pavucontrol
    rclone-browser
    vim
    vscode.fhs  # VSCode with FHS environment
  ];

  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;
  myModules.attic-client = {
    enable = true;  # Robust post-build hook that never fails builds
    tokenFile = ../../../secrets/attic-client-token.yaml.enc;  # Use global token file
  };

  # Enable snap support
  myModules.snap = {
    enable = true;
    packages = [ ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
