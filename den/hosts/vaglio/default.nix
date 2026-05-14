{
  lib,
  ...
}:

let
  denLib = import ../../lib.nix { inherit lib; };
in
denLib.mkInventoryHostModule {
  name = "vaglio";
}
