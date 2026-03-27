{ lib, ... }:

let
  currentDir = ./.;
  moduleLoading = import ../../lib/flake/module-loading.nix { inherit lib; };
  excludeItems = [
    "default.nix"
    "attic-client.nix"
    "attic-observatory.nix"
    "attic-post-build-hook.nix"
    "common"
    "inference-vm"
    "inference-vm-nix-overrides.nix"
    "sessions"
    "garuda-themed-gnome.nix"
    "garuda-themed-kde.nix"
    "x11-session-support.nix"
  ];
in
{
  imports =
    moduleLoading.mkAutoImportWithBlacklist {
      dir = currentDir;
      blacklist = excludeItems;
    }
    ++ [ ./common ];
}
