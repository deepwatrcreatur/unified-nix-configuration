{ lib, ... }:

let
  commonDir = ./common;
  moduleLoading = import ../lib/flake/module-loading.nix { inherit lib; };
in
{
  imports =
    moduleLoading.mkAutoImportFilesOnly {
      dir = commonDir;
    }
    ++ [ ./nixos ];
}
