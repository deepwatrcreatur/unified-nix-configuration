{ config, pkgs, lib, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  # Disable nh clean on Ubuntu - it requires NixOS/Darwin system config
  programs.nh.clean.enable = lib.mkForce false;
}
