{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./justfile.nix
    ../../../../modules/home-manager/gpg-desktop-linux.nix
    #../../../../modules/home-manager/ghostty
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  # Augment XDG_DATA_DIRS for this host to include nix profile
  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/bin:$XDG_DATA_DIRS";
  };

  home.packages = with pkgs; [
    bitwarden
    megacmd
    ffmpeg
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  
}
