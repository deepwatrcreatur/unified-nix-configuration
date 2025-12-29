{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Import all .nix modules from the modules directory
  importAllModulesInDir =
    dir:
    let
      items = builtins.readDir dir;
      isNixFile = name: type: type == "regular" && lib.hasSuffix ".nix" name;
      excludeList = [ "gpu-infrastructure.nix" "ollama.nix" "llama-cpp.nix" ];
      shouldInclude = name: !(builtins.elem name excludeList);
      nixFileNames = lib.filter shouldInclude (lib.attrNames (lib.filterAttrs isNixFile items));
    in
    map (fileName: dir + "/${fileName}") nixFileNames;
in
{
  # Common configuration for all inference VMs
  # This automatically imports all modules from the modules/ subdirectory

  imports = importAllModulesInDir ./modules;
}
