{ config, lib, pkgs, ... }: {
  programs.bat = {
    enable = true;
    config.theme = "onehalf";
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
