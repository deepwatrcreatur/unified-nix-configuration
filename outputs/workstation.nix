# outputs/workstation.nix
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "workstation";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos/workstation;
  isDesktop = true;
  extraModules = [
    ../hosts/nixos/default.nix
  ];
})
