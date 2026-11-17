# HP Compaq Elite 8300 SFF (i7-3770, 16 GB, UEFI). Written from the Proxmox
# install's lspci/lsblk; regenerate with `just install ... hw=` if it drifts.
{ config, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  # GOTCHA: the X520-2 is Oracle-branded (subsystem 108e:7b11). ixgbe refuses
  # its non-Intel SFP+ modules (DELY-TECH SR optic, OEM DAC) without this, and
  # the port then shows no carrier and no laser.
  boot.extraModprobeConfig = ''
    options ixgbe allow_unsupported_sfp=1
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
