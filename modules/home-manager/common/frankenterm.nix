{ config, lib, pkgs, ... }:

let
  cfg = config.programs.frankenterm;
in
{
  options.programs.frankenterm = {
    enable = lib.mkEnableOption "FrankenTerm (ft) - swarm-native terminal platform and agent orchestrator";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.frankenterm ];
  };
}
