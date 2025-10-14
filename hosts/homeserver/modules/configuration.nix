{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../modules/nixos/networking.nix
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/nixos/common  # Only import common nixos modules (SSH keys, etc.)
    ../../../modules/nixos/attic-client.nix  # Cache client
    ../../../modules/linux/linuxbrew-system.nix
    ../../nixos-lxc/lxc-systemd-suppressions.nix
    #./packages.nix
    #./podman.nix
    #./influxdb.nix
    #./users.nix
    ./sops.nix
    #./nginxproxymanager.nix
    #./zoraxy.nix
  ];

  networking.hostName = "homeserver";

  # Ensure SSH is enabled for SOPS
  services.openssh.enable = true;
  services.nginx-proxy-manager.enable = true;
  
  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;

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
