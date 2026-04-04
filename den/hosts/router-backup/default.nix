{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router-backup";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router-backup/default.nix
  ];
  extraImports = [
    # Transitional bridge: router-backup is exported through den, but still
    # reuses legacy router-backup host files until the router migration is
    # finished in smaller refactor PRs.
    ../../../hosts/nixos/router-backup/hardware-configuration.nix
    ../../../hosts/nixos/router-backup/networking.nix
    ../../../hosts/nixos/router-backup/caddy.nix
    ../../../hosts/nixos/router-backup/configuration.nix
  ];
}
