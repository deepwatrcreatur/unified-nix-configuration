{ lib, ... }:

let
  currentDir = ./.;
  moduleImports = lib.mapAttrsToList (name: _: currentDir + "/${name}") (
    lib.filterAttrs (
      name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
    ) (builtins.readDir currentDir)
  );
in
{
  imports = moduleImports;
}
