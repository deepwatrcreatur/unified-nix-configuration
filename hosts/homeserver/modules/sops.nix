{ config, pkgs, ... }:
{
  sops.age.keyFile = "/etc/nixos/secrets/age-key.txt";
  sops.validateSopsFiles = false; # or true, if you want validation
}

