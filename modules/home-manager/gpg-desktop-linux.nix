# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  home.packages = [ pkgs.pinentry-gnome3 ];

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    # Choose one based on your desktop environment (e.g., GNOME, KDE, XFCE)
    #pinentry.package = pkgs.pinentry-qt;
    pinentry.package = pkgs.pinentry-gnome3;
  };
}
