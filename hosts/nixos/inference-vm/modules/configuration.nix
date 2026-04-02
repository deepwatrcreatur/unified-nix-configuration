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
    ../../../../den/aspects/nix-caches.nix
    ../../../../modules/nixos/common/agenix.nix
    ../../../../modules/nixos/common/nix-ci-netrc.nix
    ../../../../modules/nixos/common/agenix-machine-identity.nix
    ../../../../modules/nixos/inference-vm-nix-overrides.nix
    ../../../../modules/nixos/root-ssh-identity.nix
    ../../../../modules/nixos/deepwatrcreatur-ssh-identity.nix
    ../../../../modules/nixos/snapper.nix
    ../../../../modules/nixos/determinate-netrc-dir.nix
    # inputs.nix-attic-infra.nixosModules.attic-client  # Disabled - requires sops-nix
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # New installs should bootstrap directly onto the stable machine identity path.
  my.agenix.machineIdentity.enable = true;

  my.root-ssh-identity.enable = true;
  my.deepwatrcreatur-ssh-identity.enable = true;

  # Nixpkgs configuration — GPU-specific flags live in inference-vm-nvidia.nix
  nixpkgs.config.allowUnfree = true;

  # Attic client configuration (using agenix for token)
  # The nix-attic-infra module is disabled since it requires sops-nix internally
  # Configure attic manually via the attic CLI using the token from agenix

  # Base VM configuration for inference machines and services
  services = {
    # Enable QEMU Guest Agent for better VM management
    qemuGuest.enable = true;
    openssh.enable = true;
    netdata.enable = true;
    tailscale.enable = true;

    # Ollama disabled in base config - configured per-host
    # (e.g., inference1 uses custom build with official binaries)
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  # Boot loader configuration for UEFI with Limine
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      limine.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Prefer serial console on Proxmox for headless GPU VMs
    kernelParams = lib.mkAfter [ "console=ttyS0,115200" ];
  };

  # Run a getty on the Proxmox serial console (ttyS0)
  systemd.services."serial-getty@ttyS0".enable = true;

  services.fstrim.enable = true;

  # Time zone
  time.timeZone = "America/Toronto";

  # Locale settings
  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
  };

  # Enable console login
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  system.stateVersion = "25.05";
}
