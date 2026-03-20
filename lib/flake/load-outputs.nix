{
  inputs,
  nixpkgsLib,
  shared,
  helpers,
  repoRoot,
}:
outputsDir:
let
  outputFiles = shared.importAllModulesInDir outputsDir;
  outputContext = {
    inherit
      inputs
      nixpkgsLib
      helpers
      ;
    inherit (shared)
      commonNixpkgsConfig
      commonOverlays
      systemSpecialArgs
      homeManagerModuleArgs
      importAllModulesInDir
      ;
  };
in
nixpkgsLib.foldl' (
  acc: file: nixpkgsLib.recursiveUpdate acc (import file outputContext)
) { } outputFiles
