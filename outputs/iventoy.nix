{
  inputs,
  commonNixpkgsConfig,
  commonOverlays,
  ...
}:
let
  system = "x86_64-linux";
  iventoyOverlay = import ../overlays/iventoy.nix;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = commonNixpkgsConfig;
    overlays = commonOverlays;
  };
in
{
  nixosModules.iventoy = ../modules/nixos/services/iventoy.nix;

  overlays.iventoy = iventoyOverlay;

  packages.${system}.iventoy-free = pkgs.iventoy-free;
}
