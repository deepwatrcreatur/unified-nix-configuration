{ lib, ... }:

let
  # Get all .nix files and directories in the current directory
  currentDir = ./.;
  items = builtins.readDir currentDir;
  # Filter out default.nix itself to prevent infinite recursion, and also the common folder which is handled separately
  validItems = lib.filterAttrs (name: _: name != "default.nix" && name != "common") items;
  # Create a list of paths to import
  moduleImports = lib.mapAttrsToList (name: _: currentDir + "/${name}") validItems;
in
{
  imports = moduleImports ++ [ ./common ];
}
