{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    #../../../../modules/home-manager/gpg-desktop-linux.nix
    ../../../../modules/home-manager/ghostty
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden
    firefox
    ghostty
    google-chrome[]
    megacmd
    ffmpeg
    virt-viewer
  ];
}
