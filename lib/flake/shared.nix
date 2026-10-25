{
  inputs,
  nixpkgsLib,
  repoRoot,
  utils,
}:
let
  commonNixpkgsConfig = {
    allowUnfree = true;
  };

  commonOverlays = import (repoRoot + "/overlays") {
    inherit inputs commonNixpkgsConfig nixpkgsLib;
  };

  systemSpecialArgs = {
    inherit inputs;
    lib = nixpkgsLib;
  };

  homeManagerModuleArgs = {
    inherit inputs;
  };
in
{
  inherit
    commonNixpkgsConfig
    commonOverlays
    systemSpecialArgs
    homeManagerModuleArgs
    ;

  inherit (utils)
    importAllModulesInDir
    autoImportCommon
    mkPlatformModule
    ;
}
