{
  inputs,
  commonNixpkgsConfig,
  commonOverlays,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = commonNixpkgsConfig;
    overlays = commonOverlays;
  };
in
{
  nixosModules.iventoy = ../modules/nixos/services/iventoy.nix;

  overlays.iventoy = final: prev: {
    iventoy-free = prev.callPackage ../pkgs/iventoy-free.nix { };
  };

  packages.${system}.iventoy-free = pkgs.iventoy-free;
}
