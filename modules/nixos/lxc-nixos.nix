# modules/nixos/lxc-nixos.nix - LXC Container optimizations
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # LXC Container specific settings
  boot.isContainer = true;
  # lxc-container.nix module handles the bootloader, don't set initScript here
  boot.loader.initScript.enable = false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.limine.enable = lib.mkForce false;

  # Disable services not needed in containers
  services.udisks2.enable = lib.mkDefault false;
  services.upower.enable = lib.mkDefault false;
  powerManagement.enable = lib.mkDefault false;

  # Optimize for container environment
  systemd.services.systemd-resolved.enable = lib.mkDefault false;
  services.resolved.enable = lib.mkDefault false;

  # Container networking
  networking.useDHCP = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault false;

  # Reduce memory usage
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  # Disable unnecessary filesystems
  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "btrfs"
    "xfs"
  ];

  # Container-optimized kernel parameters
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.core.default_qdisc" = "fq";
  };
}
