{ config, pkgs, lib, ... }:

{
  # System-wide SOPS configuration
  sops.age.keyFile = "/var/lib/sops/age/keys.txt";
  sops.defaultSopsFile = ../../../.sops.yaml;
}
