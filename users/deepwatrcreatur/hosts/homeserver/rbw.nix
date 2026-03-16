{ config, pkgs, ... }:
{
  programs.rbw.settings.pinentry = pkgs.pinentry-curses;
}
