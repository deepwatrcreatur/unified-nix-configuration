# outputs/phoenix.nix
# Backup of workstation with virtual display - for emergency use only
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "phoenix";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos/phoenix;
  isDesktop = true;
  extraModules = [
    ../hosts/nixos/default.nix
  ];

})
