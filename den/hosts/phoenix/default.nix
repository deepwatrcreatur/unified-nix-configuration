{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "phoenix";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    inputs.nix-whitesur-config.homeManagerModules.default
    ../../../users/deepwatrcreatur/hosts/workstation
  ];
  extraImports = [
    inputs.disko.nixosModules.disko
    inputs.nix-omarchy-screen-mirroring.nixosModules.default
    inputs.nix-omarchy-iphone-mirror.nixosModules.default
    ../../../hosts/nixos/phoenix/disko.nix
    ../../../hosts/nixos/phoenix/hardware-configuration.nix
    ../../../hosts/nixos/phoenix/networking.nix

    {
      services.omarchy-screen-mirroring.enable = true;
      services.omarchy-iphone-mirror.enable = true;
    }

    {
      boot.loader = {
        systemd-boot.enable = lib.mkForce false;
        limine = {
          enable = lib.mkForce true;
          efiInstallAsRemovable = true;
          biosSupport = true;
          biosDevice = "/dev/disk/by-id/nvme-TEAM_TM8FPK002T_TPBF2401080020300197";
          partitionIndex = 3;
        };
        efi.canTouchEfiVariables = lib.mkForce false;
      };
    }
  ];
}
