{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "attic-cache";
  aspectsList = [
    "attic-cache-core"
    "attic-cache-build-server"
    "attic-cache-home-manager"
  ];
}
