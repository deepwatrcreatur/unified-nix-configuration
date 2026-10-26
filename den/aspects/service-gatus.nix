# den/aspects/service-gatus.nix
# Automated fleet status dashboard aspect (Gatus)
{ ... }:
{ config, ... }:
{
  imports = [
    ../../modules/nixos/services/gatus-inventory.nix
  ];

  services.gatus-inventory.enable = config.networking.hostName == "router";
}
