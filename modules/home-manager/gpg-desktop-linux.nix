# modules/home-manager/gpg-desktop-linux.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Install pinentry-gtk2 for universal compatibility
  # GTK2 works on Cosmic (GTK-based), over SSH, and as fallback for all environments
  # More compatible than GNOME3 (GNOME-specific) or Qt (KDE-specific)
  home.packages = with pkgs; [
    pinentry-gtk2
  ];

  programs.gpg = {
    enable = true;
  };

  # Set up shell initialization for GPG
  programs.bash.initExtra = ''
    export GPG_TTY=$(tty)
  '';

  programs.fish.shellInit = lib.mkAfter ''
    set -gx GPG_TTY (tty)
  '';

  programs.zsh.initContent = ''
    export GPG_TTY=$(tty)
  '';

  services.gpg-agent = {
    enable = true;
    # Use GTK2 pinentry: universal compatibility (works locally and over SSH)
    pinentry.package = pkgs.pinentry-gtk2;
    enableSshSupport = true;
  };
}
