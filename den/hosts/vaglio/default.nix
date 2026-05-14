{
  lib,
  ...
}:

let
  denLib = import ../../lib.nix { inherit lib; };
in
denLib.mkInventoryHostModule {
  name = "vaglio";
  extraImports = [
    ../../../hosts/nixos/vaglio/default.nix
  ];
}
