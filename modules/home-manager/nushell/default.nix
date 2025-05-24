# modules/home-manager/nushell/default.nix
{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    envFile.source = ./env.nu;
  };
}
