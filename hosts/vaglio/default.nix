{
  lib,
  ...
}:

let
  denLib = import ../../den/lib.nix { inherit lib; };
in
denLib.mkInventoryHostModule {
  name = "vaglio";
}
