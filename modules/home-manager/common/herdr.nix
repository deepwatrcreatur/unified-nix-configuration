{ config, lib, pkgs, ... }:

let
  cfg = config.programs.herdr;
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr - a terminal-native agent multiplexer";
    desktopApp.enable = lib.mkEnableOption "the herdr desktop app (herdr-app)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { home.packages = [ pkgs.herdr ]; })
    (lib.mkIf cfg.desktopApp.enable { home.packages = [ pkgs.herdr-app ]; })
  ];
}
