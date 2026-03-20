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
  loadOutputs = import ./load-outputs.nix {
    inherit
      inputs
      nixpkgsLib
      shared
      repoRoot
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
    ;
}
