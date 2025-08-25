{ config, lib, pkgs, ... }: let
  inherit (lib) enabled;
in {
  environment.variables = {
    MANPAGER = "bat --plain";
    PAGER    = "bat --plain";
  };
  
  home-manager.sharedModules = [{
    programs.bat = enabled {
      config.theme      = "onehalf";
      themes.onehalf.src = pkgs.writeText "onehalf.tmTheme" config.theme.tmTheme;
      config.pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
    };
    
    # Move shell aliases here
    home.shellAliases = {
      cat  = "bat";
      less = "bat --plain";
    };
  }];
}
