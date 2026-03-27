# This file is intentionally generated and can be refreshed by nixos-anywhere:
#   --generate-hardware-config nixos-generate-config ./hardware-configuration.nix
# Keep host-specific hardware detection here. Shared storage and boot layout live
# in ../../modules/disko.nix and ../../modules/configuration.nix.
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
