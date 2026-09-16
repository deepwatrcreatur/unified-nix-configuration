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
  boot.supportedFilesystems = [ "btrfs" "zfs" "xfs" ];
  boot.zfs.forceImportRoot = false;

  networking.hostId = "49d7f964";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
