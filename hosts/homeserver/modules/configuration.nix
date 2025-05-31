{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../modules/nixos/networking.nix
    ../../../modules/nixos
    ../../../modules/nixos/services/iperf3.nix
    ./packages.nix
    ./podman.nix
    ./influxdb.nix
    ./users.nix
  ];

  networking.hostName = "homeserver";
  
  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false;

  systemd.mounts = [{
    what = "debugfs";
    where = "/sys/kernel/debug";
    enable = false;
  }];

  boot.initrd.systemd.fido2.enable = false;

  system.stateVersion = "25.05";
}
