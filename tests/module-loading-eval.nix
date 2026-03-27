{ lib }:

let
  helper = import ../lib/flake/module-loading.nix { inherit lib; };

  filesOnly = helper.mkAutoImportFilesOnly {
    dir = ../modules/common;
  };

  homeManagerImports = helper.mkAutoImport {
    dir = ../modules/home-manager/common;
  };

  nixosImports = helper.mkAutoImportWithBlacklist {
    dir = ../modules/nixos;
    blacklist = [
      "default.nix"
      "common"
    ];
  };
in
lib.runTests {
  filesOnlyFindsNixFiles = {
    expr = builtins.all (path: lib.hasSuffix ".nix" (toString path)) filesOnly;
    expected = true;
  };

  autoImportIncludesDirectories = {
    expr = builtins.any (path: lib.hasInfix "/hyprland" (toString path)) homeManagerImports;
    expected = true;
  };

  blacklistSkipsDefault = {
    expr = builtins.any (path: lib.hasInfix "/default.nix" (toString path)) nixosImports;
    expected = false;
  };
}
