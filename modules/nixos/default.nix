{ lib, ... }:

let
  # Auto-import all .nix files and directories from current directory
  currentDir = ./.;
  excludeItems = [
    "default.nix"
    "common"
    "inference-vm"
    "sessions"
    "garuda-themed-gnome.nix"
    "garuda-themed-kde.nix"
    "x11-session-support.nix"
  ];
  moduleImports = lib.mapAttrsToList
    (name: _: currentDir + "/${name}")
    (lib.filterAttrs
      (name: _: !lib.elem name excludeItems)
      (builtins.readDir currentDir)
    );
in
{
  imports = moduleImports ++ [ ./common ];
}
