# outputs/gateway.nix
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "gateway";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos/gateway;
  isDesktop = false;
})
