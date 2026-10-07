# hosts/nixos/lattitude/hardware-configuration.nix
# AMD E1-2100 APU with Radeon HD 8210 Graphics (HP 15 / Compaq laptop)
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
    "ahci"
    "xhci_pci"
    "ehci_pci"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "r8169"
  ];
  boot.initrd.kernelModules = [ "radeon" "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.supportedFilesystems = [ "btrfs" ];

  networking.hostId = "6412a8c6";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
}
