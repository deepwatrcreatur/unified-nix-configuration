{ lib, ... }:

let
  # Path to the common directory
  commonDir = ../common;

  # Get all files in the common directory
  commonFiles = builtins.readDir commonDir;

  # Filter only .nix files but exclude nix-settings.nix for LXC
  modules = lib.filterAttrs (name: type: 
    type == "regular" && 
    lib.hasSuffix ".nix" name && 
    name != "nix-settings.nix"
  ) commonFiles;
  
  moduleImports = lib.mapAttrsToList (name: _: import (commonDir + "/${name}")) modules;

in {
  imports = moduleImports ++ [
    # Use LXC-specific nix settings instead of the regular one
    ./nix-settings-lxc.nix
    # SOPS configuration for secrets management
    ./common/sops.nix
  ];
}