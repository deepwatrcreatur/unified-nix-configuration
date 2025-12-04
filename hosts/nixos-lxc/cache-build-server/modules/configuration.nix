{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../../modules/nixos/networking.nix
  ];

  # SOPS configuration for secrets management
  sops.age.keyFile = "/var/lib/sops/age/keys.txt";

  # Enable OpenSSH (also satisfies sops-nix requirement)
  services.openssh.enable = true;

  networking.hostName = "cache-build-server";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  security.wrappers.sudo.setuid = true;

  systemd.mounts = [{
    what = "debugfs";
    where = "/sys/kernel/debug";
    enable = false;
  }];

    # No bootloader is needed for LXC
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  system.stateVersion = "25.05";
}
