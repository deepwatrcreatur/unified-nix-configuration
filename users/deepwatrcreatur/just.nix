# users/deepwatrcreatur/just.nix
{ config, pkgs, lib, ... }:
{
  home.packages = [ pkgs.just ];

  home.file.".justfile".source = ./justfile;
}
