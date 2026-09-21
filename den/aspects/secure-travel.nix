# den/aspects/secure-travel.nix
# Secure travel hardened specialization aspect for mobile / laptop nodes.
# Activates kernel sysctl hardening, MAC randomization, VPN drop notification,
# and attack surface reduction under a dedicated "secure-travel" boot menu entry.
{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/specializations/secure-travel.nix
  ];

  myModules.specializations.secureTravel.enable = true;
}
