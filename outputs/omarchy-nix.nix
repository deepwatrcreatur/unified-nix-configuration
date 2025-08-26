# outputs/omarchy-nix.nix
{ helpers, ... }:
{
  nixosConfigurations.omarchy-nix = helpers.mkOmarchySystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/omarchy-nix;
  };
}