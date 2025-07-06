{ config, pkgs, ... }:
{
  programs.rbw.settings.pinentry = pkgs.pinentry_mac; # macOS-specific pinentry
}
