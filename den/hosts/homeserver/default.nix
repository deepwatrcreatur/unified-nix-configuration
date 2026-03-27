{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "homeserver";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/homeserver
  ];
  aspectsList = [
    "nixos-base"
    "lxc-core"
    "attic-client"
    "nix-daemon-user-ssh"
    "home-manager-users"
    "homeserver-networking"
    "homeserver-iperf3"
    "homeserver-authentik"
    "homeserver-homebridge"
    "homeserver-semaphore"
    "rustdesk-server"
  ];
}
