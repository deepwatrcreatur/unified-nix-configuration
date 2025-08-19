# modules/home-manager/default.nix
{ config, pkgs, lib, ... }:
let
  # Helper to import all .nix files from common directory
  commonDir = ./common;
  commonFiles = builtins.readDir commonDir;
  commonModules = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) commonFiles;
  commonImports = lib.mapAttrsToList (name: _: commonDir + "/${name}") commonModules;
in
{
  imports = commonImports;
  
  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };
  home.file.".ssh/config".source = ./ssh-config;
  programs.home-manager.enable = true;
}
