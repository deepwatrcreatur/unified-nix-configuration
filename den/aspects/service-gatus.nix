# den/aspects/service-gatus.nix
# Automated fleet status dashboard aspect (Gatus)
{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/services/gatus-inventory.nix
  ];

  services.gatus-inventory = {
    enable = true;
    address = "0.0.0.0";
    openFirewall = true;
  };
}
