{ lib, ... }:

let
  # Get all .nix files and directories in the current directory
  currentDir = ./.;
  items = builtins.readDir currentDir;
  # Filter out default.nix itself to prevent infinite recursion, and also the common folder which is handled separately
  # Also exclude inference-vm which should only be imported explicitly by inference hosts
  # Exclude desktop environment modules which should only be imported explicitly
  validItems = lib.filterAttrs (name: _: 
    name != "default.nix" && 
    name != "common" && 
    name != "inference-vm" &&
    name != "garuda-themed-gnome.nix" &&
    name != "garuda-themed-kde.nix" &&
    name != "x11-session-support.nix"
  ) items;
  # Create a list of paths to import
  moduleImports = lib.mapAttrsToList (name: _: currentDir + "/${name}") validItems;
in
{
  imports = moduleImports ++ [ ./common ];
}
