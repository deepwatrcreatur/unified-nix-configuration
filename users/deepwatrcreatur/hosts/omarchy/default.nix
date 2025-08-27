{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ../../../../modules/home-manager/ghostty
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden
    ghostty
    megacmd
    ffmpeg
    virt-viewer
  ];
}
