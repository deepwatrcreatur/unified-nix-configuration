{ lib, ... }:
let
  denPrototype = import ../../lib.nix { inherit lib; };
in
denPrototype.mkHostModule {
  name = "rustdesk";
  aspectsList = [
    "nixos-base"
    "lxc-core"
    "attic-client"
    "nix-daemon-user-ssh"
    "home-manager-users"
    "rustdesk-server"
  ];
}
