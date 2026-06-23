{ config, lib, pkgs, ... }:

let
  cfg = config.programs.herdr;
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr - a terminal-native agent multiplexer";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];
  };
}
