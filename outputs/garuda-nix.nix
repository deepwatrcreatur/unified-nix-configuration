# outputs/garuda-nix.nix
{ helpers, ... }:
{
  nixosConfigurations.garuda-nix = helpers.mkGarudaSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/garuda-nix;
  };
}