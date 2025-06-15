# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ inputs.home-manager.modules.programs.gnupg ];`:q`  
  programs.gnupg = {
    enable = true;
    pinentry.enable = true;
    # Choose one based on your desktop environment (e.g., GNOME, KDE, XFCE)
    pinentry.program = "${pkgs.pinentry-gtk2}/bin/pinentry-gtk2";
    # Or pinentry.program = "${pkgs.pinentry-qt}/bin/pinentry-qt";
  };
}
