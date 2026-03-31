{ lib, inputs, ... }:
{
  imports = [
    ../gateway/configuration.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router";

  services.router-homelab.sshTarget = lib.mkForce "ssh router.deepwatercreature.com";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Logs disk is on scsi1 (spinning disk), formatted by disko as disk-logs-logs.
  # router-log-storage handles the mount; disko only formats the partition.
  services.router-log-storage.device = lib.mkForce "/dev/disk/by-partlabel/disk-logs-logs";
}
