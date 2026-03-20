{ lib, ... }:
let
  denPrototype = import ../../lib.nix { inherit lib; };
in
denPrototype.mkHostModule {
  name = "podman";
  primaryUser = "deepwatrcreatur";
  extraGroups = [
    "wheel"
    "podman"
  ];
  primaryUserImports = [
    ../../../../users/deepwatrcreatur/hosts/podman
  ];
  aspectsList = [
    "nixos-base"
    "lxc-core"
    "attic-client"
    "nix-daemon-user-ssh"
    "home-manager-users"
    "podman-lxc-suppressions"
    "podman-containers"
  ];
}
