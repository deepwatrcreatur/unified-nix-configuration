{ pkgs ? null }:
let
  # NixOS hosts that can use remote building (via agenix)
  nixosHosts = [
    "homeserver"
    "router"
    "workstation"
  ];

  # Non-NixOS hosts that can use remote building (Proxmox, Ubuntu)
  # These use home-manager/ansible for key deployment
  nonNixosHosts = [
    "pve-rog"
    "pve-strix"
    "pve-tomahawk"
    "pve-lattitude"
    "pve-z170"
  ];

  supportedHosts = nixosHosts ++ nonNixosHosts;
in
{
  inherit supportedHosts nixosHosts nonNixosHosts;

  keyPath =
    if pkgs != null && pkgs.stdenv.isDarwin then
      "/var/root/.ssh/nix-remote"
    else
      "/root/.ssh/nix-remote";

  canUse = hostName: hostName != "attic-cache" && builtins.elem hostName supportedHosts;
  canUseNixOS = hostName: builtins.elem hostName nixosHosts;
}
