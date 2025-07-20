{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../modules/nixos/networking.nix
    ../../../modules/nixos
    ../../../modules/nixos/services/iperf3.nix
  ];

  networking.hostName = "nixos_lxc";

  security.sudo.wheelNeedsPassword = false;

  systemd.mounts = [{
    what = "debugfs";
    where = "/sys/kernel/debug";
    enable = false;
  }];

  boot.initrd.systemd.fido2.enable = false;

  system.stateVersion = "25.05";
}
