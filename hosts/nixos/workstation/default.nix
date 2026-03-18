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
    inputs.nix-attic-infra.nixosModules.attic-client # Re-enabled with agenix support
    inputs.nixbit.nixosModules.nixbit # Nix bit repository manager
    inputs.agenix.nixosModules.default # Agenix secrets management (testing alongside sops)
    ../../../modules/nixos/snap.nix # Snap package manager support
    #../../../modules/nixos/sessions/cinnamon.nix # MATE with WhiteSur theming

    # Desktop environment - choose one:
    # COSMIC: Clean GNOME-based, excellent Activities, no app badges
    ../../../modules/nixos/sessions/cosmic.nix
    # KDE Plasma (testing): Powerful, app badges in system tray, Super+Space launcher, Desktop Grid
    #../../../modules/nixos/sessions/whitesur-themed-kde.nix

    ../../../modules/nixos/hp-print-scan.nix # HP printer/scanner support
    ../../../modules/nixos/printers/phoenix-hp-m477.nix # HP M477 printer queue
    ../../../modules/nixos/keyboard-glitches.nix # Fix for stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snapper.nix # Btrfs snapshots via Snapper
    ../../../modules/nixos/nix-daemon-user-ssh.nix # SSH socket for git+ssh flake inputs
    ../../../modules/wezterm-config.nix
    ../../../modules/activation-scripts # Activation scripts for system setup
  ];

  # Declarative host configuration using options-based system
  host = {
    type = "workstation";
    primaryUser = "deepwatrcreatur";
    gpu = {
      type = "amd";
      enableRocm = false;  # Enable if ROCm support needed
    };
    desktop = {
      enable = true;
      environment = "cosmic";  # Using COSMIC desktop
      enableSound = true;
      enablePrinting = true;
    };
    networking = {
      enableTailscale = true;
      enableAvahi = true;
    };
    services = {
      enableSsh = true;
      enableDocker = true;
      enablePodman = false;
    };
    cache = {
      server = "http://attic-cache:5001";
      enableClient = true;
    };
  };

  # Homebrew is managed via home-manager (modules/home-manager/linuxbrew.nix)
  # System-level Linuxbrew setup and Homebrew compatibility links live in
  # modules/activation-scripts/linux/linuxbrew-system.nix.
  custom.activation-scripts.linux.linuxbrew-system.enable = true;

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
    enable = false;
    videoDrivers = [ "amdgpu" ];
    xkb.options = "caps:none"; # Let input-leap handle caps lock synchronization
  };
  hardware.graphics.enable = true;

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

  # Enable Avahi for mDNS (service discovery)
  services.avahi = {
    enable = true;
    nssmdns4 = true; # For resolving .local hostnames
    openFirewall = true;
  };

  systemd.services."ensure-printers".serviceConfig = lib.mkIf config.services.printing.enable {
    # Ensure the printer setup command's failure doesn't block the system activation.
    ContinueOnError = true;
  };

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

  services.ssh-keys-manager.username = "deepwatrcreatur";

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
    baobab # Disk usage analyzer (GUI)
    distrobox
    dosfstools # FAT filesystem utilities (mkfs.vfat, fsck.vfat)
    filezilla
    gnome-disk-utility # GNOME Disks - GUI disk management tool (supports FAT32 formatting)
    gparted # Partition editor (GUI - supports FAT32 formatting)
    nushell # Stopgap: Add nushell at system level for ghostty compatibility
    nvtopPackages.amd # GPU monitoring tool for AMD GPUs
    parted # Command-line partition manager
    pavucontrol
    rclone-browser
    remmina # Remote desktop client for VNC, RDP, and other protocols
    realvnc-vnc-viewer # RealVNC VNC Viewer for connecting to macOS screen sharing
    usbutils
    vscode.fhs # VSCode with FHS environment
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    xdg-desktop-portal-gtk # GTK desktop portal
    satty # Screenshot annotation tool inspired by Swappy and Flameshot
    gthumb # Image browser and viewer with crop support
    yt-dlp # YouTube and video downloader
    vivaldi # Chromium-based browser with advanced features
  ];

  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;

  # Enable Podman for distrobox
  virtualisation.podman.enable = true;

  # Enable QEMU guest agent for Proxmox integration
  services.qemuGuest.enable = true;

  # Enable nix-daemon to use user's SSH socket for git+ssh flake inputs
  myModules.nix-daemon-user-ssh.enable = true;
  my.agenix.machineIdentity.enable = true;

  # Attic client with agenix backend (nix-attic-infra feat/agenix-support)
  services.attic-client = {
    enable = true;
    secretsBackend = "agenix";
    ageSecretFile = ../../../secrets-agenix/attic-client-token.age;
    server = "http://attic-cache:5001";
    cache = "cache-local";
    enablePostBuildHook = true;
    configureNixSubstituter = false;  # Already configured via nix-settings
  };

  nixbit = {
    enable = true;
    repository = "https://github.com/deepwatrcreatur/unified-nix-configuration.git";
    forceAutostart = true; # Ensure autostart on all systems
  };

  # Enable snap support
  myModules.snap = {
    enable = true;
    classicPackages = [ "icloud-for-linux" ];
  };

  # Enable fixes for stuck keyboard presses in Proxmox VM
  myModules.keyboardGlitches.enable = true;

  # nix.buildMachines is now managed by modules/common/nix-settings.nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  services.resolved.enable = true; # Explicitly enable systemd-resolved for automatic DNS management
  system.stateVersion = "25.05";
}
