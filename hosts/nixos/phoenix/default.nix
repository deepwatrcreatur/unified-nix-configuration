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
    ../../../modules/nixos/attic-client.nix # Attic cache client
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/nixos/sessions/cosmic.nix # COSMIC desktop with native Wayland
    #../../../modules/nixos/sessions/hyprland/default.nix # Hyprland Wayland compositor (backup)
    #../../../modules/nixos/sessions/cosmic.nix # COSMIC desktop
    #../../../modules/nixos/sessions/cinnamon.nix
    ../../../modules/nixos/keyboard-glitches.nix # Fix for stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snapper.nix # Btrfs snapshots via Snapper
    ../../../modules/wezterm-config.nix
    ../../../modules/activation-scripts # Activation scripts for system setup
  ];

  # Homebrew is managed via home-manager (modules/home-manager/linuxbrew.nix)
  # Create /home/linuxbrew with correct ownership for install.sh
  custom.activation-scripts.linux.linuxbrew-system.enable = true;

  # Symlink nice to /usr/bin for Homebrew's Ruby (needed by some formulae like bd)
  system.activationScripts.homebrewCompat = ''
    mkdir -p /usr/bin
    ln -sf ${pkgs.coreutils}/bin/nice /usr/bin/nice

    # Homebrew's installer uses absolute /bin/* and /usr/bin/* paths.
    mkdir -p /bin /usr/bin
    ln -sf ${pkgs.coreutils}/bin/mkdir /bin/mkdir
    ln -sf ${pkgs.coreutils}/bin/chmod /bin/chmod
    ln -sf ${pkgs.coreutils}/bin/chown /bin/chown
    ln -sf ${pkgs.coreutils}/bin/chgrp /bin/chgrp
    ln -sf ${pkgs.coreutils}/bin/touch /bin/touch
    ln -sf ${pkgs.coreutils}/bin/readlink /bin/readlink
    ln -sf ${pkgs.coreutils}/bin/cat /bin/cat
    ln -sf ${pkgs.coreutils}/bin/sort /bin/sort
    ln -sf ${pkgs.coreutils}/bin/mv /bin/mv
    ln -sf ${pkgs.coreutils}/bin/rm /bin/rm
    ln -sf ${pkgs.coreutils}/bin/sha256sum /bin/sha256sum
    ln -sf ${pkgs.gnutar}/bin/tar /bin/tar
    ln -sf ${pkgs.gzip}/bin/gzip /bin/gzip
    ln -sf ${pkgs.gnugrep}/bin/grep /bin/grep
    ln -sf ${pkgs.util-linux}/bin/flock /usr/bin/flock
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
    ln -sf ${pkgs.coreutils}/bin/stat /usr/bin/stat
    ln -sf ${pkgs.coreutils}/bin/cut /usr/bin/cut
    ln -sf ${pkgs.coreutils}/bin/sha256sum /usr/bin/sha256sum
    ln -sf ${pkgs.glibc.bin}/bin/ldd /usr/bin/ldd
  '';

  # Linux-specific wezterm configuration
  programs.wezterm.extraConfig = lib.mkAfter ''
    -- Default program: launch zellij with nushell as default shell (Linux path)
    config.default_prog = { '/etc/profiles/per-user/deepwatrcreatur/bin/zellij', '-l', 'welcome' }
  '';

  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.limine.enable = true;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.bootspec.enable = true;
  boot.growPartition = false;

  # Virtual display (virtio-gpu) for Proxmox VM
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Configure keyboard and X11
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb.options = "caps:none"; # Let input-leap handle caps lock synchronization
  };

  # GDM and autologin now configured in modules/nixos/sessions/gnome.nix
  # greetd disabled - GNOME requires GDM for proper systemd user session integration

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

  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../users/deepwatrcreatur/hosts/phoenix
    ];
  };

  # Additional system packages (utility-packages provides: git, vim, curl, wget, rsync, nmap, openssl, etc.)
  environment.systemPackages = with pkgs; [
    at-spi2-core # Accessibility framework for deskflow clipboard
    distrobox
    filezilla
    nushell # Stopgap: Add nushell at system level for ghostty compatibility
    pavucontrol
    rclone-browser
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

  # Attic cache client for automatic build uploads
  myModules.attic-client = {
    enable = true;
    tokenFile = ../../../secrets/attic-client-token.yaml.enc;
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
