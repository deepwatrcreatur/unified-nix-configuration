# outputs/rustdesk.nix - RustDesk Server LXC Container
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "rustdesk";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos-lxc/rustdesk;
  isDesktop = false;
  extraModules = [
    ../hosts/nixos-lxc/lxc-systemd-suppressions.nix
    ../hosts/nixos # Base NixOS config
  ];
})

