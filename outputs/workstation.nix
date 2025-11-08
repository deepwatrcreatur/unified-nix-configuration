# outputs/workstation.nix
{ helpers, ... }:
{
  nixosConfigurations.workstation = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/workstation;
    isDesktop = true;
    extraModules = [
      ../hosts/nixos/default.nix
    ];
  };
}