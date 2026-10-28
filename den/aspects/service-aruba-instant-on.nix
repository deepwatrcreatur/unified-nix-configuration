# den/aspects/service-aruba-instant-on.nix
# Aruba Instant On cloud portal telemetry exporter aspect
{ ... }:
{ lib, ... }:
let
  optSec = import ../../lib/optional-secrets.nix { inherit lib; };
  secrets = optSec.mkSecrets {
    aruba-instant-on-credentials = {
      file = ../../secrets-agenix/aruba-instant-on-credentials.age;
      mode = "0400";
    };
  };
in
{
  imports = [
    ../../modules/nixos/services/aruba-instant-on-exporter.nix
  ];

  services.aruba-instant-on-exporter = {
    enable = true;
    port = 9590;
    openFirewall = true;
    environmentFile = secrets.path;
  };
}
