# modules/home-manager/gpg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  # Install pinentry package (gnome3 for GNOME desktop)
  home.packages = with pkgs; [
    pinentry-gnome3
  ];

  programs.gpg = {
    enable = true;
  };

  # Set up shell initialization for GPG
  programs.bash.initExtra = ''
    export GPG_TTY=$(tty)
  '';

  programs.fish.shellInit = ''
    set -gx GPG_TTY (tty)
  '';

  programs.zsh.initExtra = ''
    export GPG_TTY=$(tty)
  '';

  services.gpg-agent = {
    enable = true;
    # Choose one based on your desktop environment (e.g., GNOME, KDE, XFCE)
    #pinentry.package = pkgs.pinentry-qt;
    pinentry.package = pkgs.pinentry-gnome3;
    # Try gtk2 pinentry which is more universally compatible
    enableSshSupport = true;
  };
}
