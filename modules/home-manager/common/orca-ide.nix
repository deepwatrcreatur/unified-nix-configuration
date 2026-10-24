# modules/home-manager/common/orca-ide.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.orca-ide;
in
{
  options.programs.orca-ide = {
    enable = lib.mkEnableOption "Orca - Agent Development Environment (ADE) by Stably";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.orca-ide ];
  };
}
