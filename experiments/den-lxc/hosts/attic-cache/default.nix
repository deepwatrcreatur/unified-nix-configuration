{ lib, ... }:
let
  denPrototype = import ../../lib.nix { inherit lib; };
in
denPrototype.mkHostModule {
  name = "attic-cache";
  aspectsList = [
    "attic-cache-core"
    "attic-cache-build-server"
    "attic-cache-home-manager"
  ];
}
