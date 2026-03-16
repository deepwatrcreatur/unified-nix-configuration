# outputs/podman.nix - NixOS Podman Container Host (LXC)
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "podman";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos-lxc/podman;
  isDesktop = false;
  extraModules = [
    ../hosts/nixos-lxc/lxc-systemd-suppressions.nix
    ../hosts/nixos  # Base NixOS config
  ];
})
