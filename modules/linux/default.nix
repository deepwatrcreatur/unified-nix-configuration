{ lib, ... }:

let
  # Path to the common directory
  commonDir = ./common;

  # Get all files in the common directory
  commonFiles = builtins.readDir commonDir;

  # Filter only .nix files and import them
  modules = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) commonFiles;
  moduleImports = lib.mapAttrsToList (name: _: import (commonDir + "/${name}")) modules;

in {
  imports = moduleImports ++ [
    # add standalone home manager for linux hosts t
    #../home-manager/env/standalone-hm.nix   
  ];
}
