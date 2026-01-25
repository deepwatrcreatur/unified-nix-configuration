# outputs/attic-cache.nix - NixOS Build Server LXC Container with Attic Cache
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "attic-cache";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos-lxc/attic-cache;
  isDesktop = false;
  extraModules = [
    ../hosts/nixos-lxc/lxc-systemd-suppressions.nix
    ../hosts/nixos # Base NixOS config
  ];
})
