# outputs/workstation.nix
{ helpers, ... }:
{
  nixosConfigurations.workstation = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/workstation;
    extraModules = [
      ../hosts/nixos/default.nix
    ];
  };
}