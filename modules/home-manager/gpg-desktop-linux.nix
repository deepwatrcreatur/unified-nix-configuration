# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    # Choose one based on your desktop environment (e.g., GNOME, KDE, XFCE)
    pinentryPackage = pkgs.pinentry-gnome3;
    # Or pinentryPackage = pkgs.pinentry-qt;
  };
}
