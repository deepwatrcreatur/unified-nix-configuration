{ lib, ... }:

let
  currentDir = ./.;
  moduleLoading = import ../../lib/flake/module-loading.nix { inherit lib; };
  excludeItems = [
    "default.nix"
    "attic-client.nix"
    "attic-observatory.nix"
    "attic-post-build-hook.nix"
    "bootstrap"
    "common"
    "inference-vm"
    "inference-vm-nix-overrides.nix"
    "lxc-common.nix"
    "lxc-dhcp-networking.nix"
    "lxc-nixos.nix"
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
      directoryPredicate = name: builtins.pathExists (currentDir + "/${name}/default.nix");
    }
    ++ [
      ./common
      ./services/roundtable.nix
    ];
}
