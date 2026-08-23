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
    ../../../hosts/nixos/phoenix/disko.nix
    ../../../hosts/nixos/phoenix/hardware-configuration.nix
    ../../../hosts/nixos/phoenix/networking.nix

    {
      boot.loader = {
        systemd-boot.enable = lib.mkForce false;
        limine.enable = lib.mkForce true;
        efi.canTouchEfiVariables = true;
      };
    }
  ];
}
