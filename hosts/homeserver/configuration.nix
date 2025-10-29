{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    "../../../modules/nixos/services/iperf3.nix"
    "../../nixos-lxc/lxc-systemd-suppressions.nix"
  ];

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

}
