# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    # Choose one based on your desktop environment (e.g., GNOME, KDE, XFCE)
    pinentry.package = pkgs.pinentry-qt;
    # Or pinentry.package = pkgs.pinentry-gnome3;
  };
}
