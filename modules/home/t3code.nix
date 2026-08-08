# modules/home/t3code.nix
# Dendritic Opt-in Home Manager Module for T3 Code
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.t3code;
in
{
  options.programs.t3code = {
    enable = lib.mkEnableOption "T3 Code - Agentic AI Coding GUI Harness by Theo Browne (@t3dotgg)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.t3code ];
  };
}
