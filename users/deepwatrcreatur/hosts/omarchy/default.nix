{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ../../../../modules/home-manager/ghostty
    ./rbw.nix
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden
    megacmd
    ffmpeg
    virt-viewer
  ];
}
