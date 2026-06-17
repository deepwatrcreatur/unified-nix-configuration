# modules/home-manager/common/dmux.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.dmux;
  dmuxPackage = pkgs.callPackage ../../../pkgs/dmux.nix { };
in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ dmuxPackage ];
  };
}
