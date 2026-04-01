{ lib, ... }:
{
  imports = [ ../router/networking.nix ];

  # Only differ in hostname; DNS and NAT settings are shared with primary router.
  networking.hostName = lib.mkForce "router-backup";
}
