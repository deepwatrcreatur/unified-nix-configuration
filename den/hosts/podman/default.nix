{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "podman";
  primaryUser = "deepwatrcreatur";
  extraGroups = [
    "wheel"
    "podman"
  ];
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/podman
  ];
  aspectsList = [
    "nixos-base"
    "lxc-core"
    "attic-client"
    "rclone-client"
    "github-token-client"
    "nix-daemon-user-ssh"
    "home-manager-users"
    "podman-lxc-suppressions"
    "podman-containers"
  ];
}
