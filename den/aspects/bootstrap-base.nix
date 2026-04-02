{ ... }:
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ../../hosts/nixos/inference-vm/modules/disko.nix
    ../../hosts/nixos/router-bootstrap/configuration.nix
  ];
}
