{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "OneHalfDark"; # Use a built-in theme
      pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
    };
  };

  home.sessionVariables = {
    MANPAGER = "bat --plain";
    PAGER = "bat --plain";
  };

  home.shellAliases = {
    less = "bat --plain";
  };
}
