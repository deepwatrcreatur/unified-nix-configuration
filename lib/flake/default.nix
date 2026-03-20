{
  inputs,
  repoRoot,
}:
let
  nixpkgsLib = inputs.nixpkgs.lib;
  utils = import ./utils.nix { inherit nixpkgsLib; };
  shared = import ./shared.nix {
    inherit
      inputs
      nixpkgsLib
      repoRoot
      utils
      ;
  };
  helperSet = import ./helpers.nix {
    inherit
      inputs
      nixpkgsLib
      repoRoot
      shared
      ;
  };
  inventoryOutputs = import ./inventory-outputs.nix {
    helpers = helperSet.helpers;
    inherit nixpkgsLib;
  };
  loadOutputs = import ./load-outputs.nix {
    inherit
      inputs
      nixpkgsLib
      shared
      repoRoot
      inventoryOutputs
      ;
    helpers = helperSet.helpers;
  };
in
shared
// helperSet
// {
  inherit
    nixpkgsLib
    repoRoot
    utils
    loadOutputs
    inventoryOutputs
    ;
}
