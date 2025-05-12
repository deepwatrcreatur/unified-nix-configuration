# modules/home-manager/common-home.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./helix.nix
    # add other shared user modules here
  ];
}

