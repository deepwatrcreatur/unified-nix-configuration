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

  home.packages = with pkgs; [
    bitwarden
    firefox
    google-chrome
    megacmd
    ffmpeg
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  
}
