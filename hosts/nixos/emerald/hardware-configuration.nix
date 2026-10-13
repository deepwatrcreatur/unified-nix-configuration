# This file can be refreshed by nixos-anywhere:
#   --generate-hardware-config nixos-generate-config ./hardware-configuration.nix
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.supportedFilesystems = [ "btrfs" "zfs" "xfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = false;

  fileSystems."/big" = {
    device = "/dev/disk/by-label/big";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
      "compress=zstd"
      "nofail"
      "x-systemd.automount"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /big 0755 deepwatrcreatur users -"
  ];

  networking.hostId = "49d7f964";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
