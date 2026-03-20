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
    myModules = import (repoRoot + "/modules");
  };

  homeManagerModuleArgs = {
    inherit inputs;
    inherit (inputs) mac-app-util;
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
