{ pkgs ? null }:
let
  # NixOS hosts that can use remote building (via agenix)
  nixosHosts = [
    "homeserver"
    "router"
    "workstation"
    "phoenix"
  ];

  # Non-NixOS hosts that can use remote building (Proxmox, Ubuntu)
  # These use home-manager/ansible for key deployment
  nonNixosHosts = [
    "pve-rog"
    "pve-strix"
    "pve-lattitude"
    "pve-z170"
  ];

  # Hosts that act as the binary cache and build server (must not use remote building)
  cacheHosts = [
    "attic-cache"
    "emerald"
  ];

  supportedHosts = nixosHosts ++ nonNixosHosts;
in
{
  inherit supportedHosts nixosHosts nonNixosHosts cacheHosts;

  keyPath =
    if pkgs != null && pkgs.stdenv.isDarwin then
      "/var/root/.ssh/nix-remote"
    else
      "/root/.ssh/nix-remote";

  canUse = hostName: !(builtins.elem hostName cacheHosts) && builtins.elem hostName supportedHosts;
  canUseNixOS = hostName: builtins.elem hostName nixosHosts;
}
