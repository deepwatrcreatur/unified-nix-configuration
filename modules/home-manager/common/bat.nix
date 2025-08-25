{ config, lib, pkgs, ... }: let
  inherit (lib) enabled;
in {
  programs.bat = enabled {
    config.theme      = "onehalf";
    themes.onehalf.src = pkgs.writeText "onehalf.tmTheme" config.theme.tmTheme;
    config.pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
  };
  
  home.sessionVariables = {
    MANPAGER = "bat --plain";
    PAGER    = "bat --plain";
  };
  
  home.shellAliases = {
    cat  = "bat";
    less = "bat --plain";
  };
}
