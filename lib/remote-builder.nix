{ pkgs ? null }:
let
  # Fallback NixOS hostnames for legacy string-based checks
  nixosHosts = [
    "homeserver"
    "router"
    "workstation"
    "phoenix"
    "sapphire"
    "ruby"
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

  canUse =
    hostOrConfig:
    if builtins.isAttrs hostOrConfig then
      (hostOrConfig.myModules.builder.canUseRemoteBuilder or false)
      && !(hostOrConfig.myModules.caches.isCacheServer or false)
    else
      !(builtins.elem hostOrConfig cacheHosts) && builtins.elem hostOrConfig supportedHosts;

  canUseNixOS =
    hostOrConfig:
    if builtins.isAttrs hostOrConfig then
      (hostOrConfig.myModules.builder.canUseRemoteBuilder or false)
      && !(hostOrConfig.myModules.caches.isCacheServer or false)
    else
      builtins.elem hostOrConfig nixosHosts;
}
