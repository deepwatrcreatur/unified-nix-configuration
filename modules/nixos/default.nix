# modules/nixos/default.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./nix-gc.nix
  ];
}

