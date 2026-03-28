{ ... }:
{ inputs, ... }:
{
  imports = [
    inputs.nix-authentik.nixosModules.default
  ];

  services.authentik = {
    enable = true;
    domain = "authentik.deepwatercreature.com";
    settings = {
      AUTHENTIK_LISTEN__HTTP = "0.0.0.0:9000";
    };
  };

  networking.firewall.allowedTCPPorts = [ 9000 ];
}
