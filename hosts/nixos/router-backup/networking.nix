{
  lib,
  ...
}:
{
  imports = [
    ../gateway/networking.nix
  ];

  networking.hostName = lib.mkForce "router-backup";
}
