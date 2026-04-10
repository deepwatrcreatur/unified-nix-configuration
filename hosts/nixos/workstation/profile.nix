{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../../../modules/nixos/common
    ../../../modules/common/utility-packages.nix
    inputs.nix-attic-infra.nixosModules.attic-client
    inputs.nixbit.nixosModules.nixbit
    inputs.agenix.nixosModules.default
    ../../../modules/nixos/snap.nix
    ../../../modules/nixos/sessions/cosmic.nix
    #../../../modules/nixos/hp-print-scan.nix
    #../../../modules/nixos/printers/phoenix-hp-m477.nix
    ../../../modules/nixos/keyboard-glitches.nix
    ../../../modules/nixos/snapper.nix
    ../../../modules/nixos/nix-daemon-user-ssh.nix
    ../../../modules/wezterm-config.nix
    ../../../modules/activation-scripts
  ];

  host = {
    type = "workstation";
    primaryUser = "deepwatrcreatur";
    gpu = {
      type = "amd";
      enableRocm = false;
    };
    desktop = {
      enable = true;
      environment = "gnome";
      enableSound = true;
      enablePrinting = true;
    };
    networking = {
      enableTailscale = true;
      enableAvahi = false;
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

  programs.linuxbrew = {
    # The generated setup hook recursively chowns the entire Linuxbrew prefix
    # on every activation, which causes workstation switches to time out.
    # The prefix already exists with the correct ownership on this host.
    enableSystemSetup = false;
  };

  programs.wezterm.extraConfig = lib.mkAfter ''
    config.default_prog = { '/etc/profiles/per-user/deepwatrcreatur/bin/zellij', '-l', 'welcome' }
  '';

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.limine.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.bootspec.enable = true;
  boot.growPartition = true;
  boot.loader.timeout = 7;
  boot.loader.systemd-boot.consoleMode = "auto";

  boot.kernelModules = [ "amdgpu" ];
  # Disable GFX power gating — prevents the amdgpu SMU gfxoff hang that causes
  # "GPU reset failed: device lost from bus" and a black screen requiring reboot.
  boot.kernelParams = [ "amdgpu.gfxoff=0" ];
  boot.blacklistedKernelModules = [
    "virtio_gpu"
    "bochs_drm"
    "qxl"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.nvidia.open = false;

  services.xserver = {
    videoDrivers = [ "amdgpu" ];
    xkb.options = "caps:none";
  };
  hardware.graphics.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.orca.enable = false;
  services.speechd.enable = false;

  services.openssh.enable = true;
  services.avahi = {
    enable = lib.mkForce false;
    nssmdns4 = lib.mkForce false;
    openFirewall = lib.mkForce false;
  };

  systemd.services."ensure-printers".serviceConfig = lib.mkIf config.services.printing.enable {
    ContinueOnError = true;
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";
  security.sudo.wheelNeedsPassword = false;

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

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    at-spi2-core
    baobab
    distrobox
    dosfstools
    filezilla
    gnome-disk-utility
    gparted
    nushell
    nvtopPackages.amd
    parted
    pavucontrol
    rclone-browser
    remmina
    realvnc-vnc-viewer
    usbutils
    vscode.fhs
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    xdg-desktop-portal-gtk
    satty
    gthumb
    ventoy-full
    yt-dlp
    vivaldi
  ];

  programs.nix-ld.enable = true;
  virtualisation.podman.enable = true;
  services.qemuGuest.enable = true;

  myModules.nix-daemon-user-ssh.enable = true;
  my.agenix.machineIdentity.enable = true;

  services.attic-client = {
    enable = true;
    secretsBackend = "agenix";
    ageSecretFile = ../../../secrets-agenix/attic-client-token.age;
    server = "http://attic-cache:5001";
    cache = "cache-local";
    enablePostBuildHook = true;
    configureNixSubstituter = false;
  };

  nixbit = {
    enable = true;
    repository = "https://github.com/deepwatrcreatur/unified-nix-configuration.git";
    forceAutostart = true;
  };

  myModules.snap = {
    enable = true;
    classicPackages = [ "icloud-for-linux" ];
  };

  myModules.keyboardGlitches.enable = true;

  nix.distributedBuilds = lib.mkForce false;
  nix.buildMachines = lib.mkForce [ ];
  nix.settings.fallback = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.10"
  ];

  services.resolved.enable = true;
  system.stateVersion = "25.05";
}
