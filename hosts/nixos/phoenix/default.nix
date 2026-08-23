{
  lib,
  ...
}:

{
  imports = [
    ../../../profiles/nixos/workstation.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    limine = {
      enable = true;
      efiInstallAsRemovable = true;
      biosSupport = true;
      biosDevice = "/dev/disk/by-id/nvme-TEAM_TM8FPK002T_TPBF2401080020300197";
      partitionIndex = 3;
    };
    efi.canTouchEfiVariables = lib.mkForce false;
  };
}
