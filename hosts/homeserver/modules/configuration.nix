{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../modules/nixos/networking.nix
    ../../../modules/nixos
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/linux/linuxbrew-system.nix
    #./packages.nix
    #./podman.nix
    #./influxdb.nix
    #./users.nix
    ./sops.nix
    #./nginxproxymanager.nix
    #./zoraxy.nix
  ];

  networking.hostName = "homeserver";

  services.nginx-proxy-manager.enable = true;
  
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
