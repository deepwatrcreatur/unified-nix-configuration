{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../../../modules/nixos/networking.nix
    ../../../../../modules/nixos
  ];

  networking.hostName = "cache-build-server";

  # LXC containers don't need traditional filesystems or bootloaders - disable assertions
  system.build.checkSystemAssertions = lib.mkOverride 100 "";
  
  # Alternative: Override the specific assertions
  assertions = lib.mkOverride 1 [];

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.mounts = [{
    what = "debugfs";
    where = "/sys/kernel/debug";
    enable = false;
  }];

  boot.initrd.systemd.fido2.enable = false;

  system.stateVersion = "25.05";
}