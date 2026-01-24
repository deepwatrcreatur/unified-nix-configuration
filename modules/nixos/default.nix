{ lib, ... }:

let
  # Auto-import all .nix files and directories from current directory
  currentDir = ./.;
  excludeItems = [
    "default.nix"
    "common"
    "inference-vm"
    "inference-vm-nix-overrides.nix"
    "sessions"
    "garuda-themed-gnome.nix"
    "garuda-themed-kde.nix"
    "x11-session-support.nix"

    # Deprecated: now consumed from inputs.nix-attic-infra.
    "attic-client.nix"
    "attic-post-build-hook.nix"
  ];
  moduleImports = lib.mapAttrsToList (name: _: currentDir + "/${name}") (
    lib.filterAttrs (name: _: !lib.elem name excludeItems) (builtins.readDir currentDir)
  );
in
{
  imports = moduleImports ++ [ ./common ];
}
