# outputs/workstation-backup.nix
# Backup of workstation with virtual display - for emergency use only
{ helpers, ... }:
(helpers.mkNixosOutput {
  name = "workstation-backup";
  system = "x86_64-linux";
  hostPath = ../hosts/nixos/workstation-backup;
  isDesktop = true;
  extraModules = [
    ../hosts/nixos/default.nix
  ];
})
