{ pkgs ? null }:
let
  # Fallback NixOS hostnames for legacy string-based checks
  # SECURITY: router-class hosts (router, elitedesk) are deliberately absent:
  # the builder key logs into emerald, and routers hold no outbound SSH keys.
  # They are deployed from a workstation with --target-host, so never build.
  nixosHosts = [
    "homeserver"
    "phoenix"
    "sapphire"
    "ruby"
    "authentik-host"
    "podman"
    "vaglio"
  ];

  # Non-NixOS hosts that can use remote building (Proxmox, Ubuntu)
  # These use home-manager/ansible for key deployment
  nonNixosHosts = [
    "pve-rog"
    "pve-strix"
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
