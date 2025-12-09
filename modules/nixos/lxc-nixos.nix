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
  boot.loader.initScript.enable = true;

  # Disable services not needed in containers
  services.udisks2.enable = false;
  services.upower.enable = false;
  powerManagement.enable = false;

  # Optimize for container environment
  systemd.services.systemd-resolved.enable = false;
  services.resolved.enable = false;

  # Container networking
  networking.useDHCP = false;
  networking.useNetworkd = false;

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
