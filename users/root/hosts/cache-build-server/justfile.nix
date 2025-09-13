# users/root/hosts/cache-build-server/justfile.nix
{ config, pkgs, lib, ... }:
{
  home.packages = [ pkgs.just ];

  home.file.".justfile".source = ./justfile;
}
