{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "authentik-host";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/authentik-host
  ];
  aspectsList = [
    "nixos-base"
    "lxc-core"
    "lxc-dhcp-networking"
    "authentik-native"
    "attic-client"
    "nix-daemon-user-ssh"
    "home-manager-users"
  ];
}
