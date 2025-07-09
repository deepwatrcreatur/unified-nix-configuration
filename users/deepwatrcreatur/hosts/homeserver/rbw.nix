{ config, pkgs, ... }:
{
  programs.rbw.settings.pinentry = pkgs.pinentry-curses; # macOS-specific pinentry
}
