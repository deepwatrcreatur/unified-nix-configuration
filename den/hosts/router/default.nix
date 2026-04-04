{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router
  ];
  extraImports = [
    # Transitional bridge: router outputs are exported through den, but the
    # host still depends on legacy router-local modules for hardware,
    # networking, Caddy, and role configuration. Keep this explicit until the
    # router tree is migrated into den/aspects in reviewable pieces.
    ../../../hosts/nixos/router/hardware-configuration.nix
    ../../../hosts/nixos/router/networking.nix
    ../../../hosts/nixos/router/caddy.nix
    ../../../hosts/nixos/router/disko.nix
    ../../../hosts/nixos/router/configuration.nix
  ];
}
