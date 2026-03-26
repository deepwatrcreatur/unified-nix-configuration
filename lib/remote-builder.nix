{ pkgs ? null }:
let
  # NixOS hosts that can use remote building (via agenix)
  nixosHosts = [
    "gateway"
    "homeserver"
    "workstation"
  ];

  # Non-NixOS hosts that can use remote building (Proxmox, Ubuntu)
  # These use home-manager/ansible for key deployment
  nonNixosHosts = [
    "pve-gateway"
    "pve-rog"
    "pve-strix"
    "pve-tomahawk"
    "pve-lattitude"
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
