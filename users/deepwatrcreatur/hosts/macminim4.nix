{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
  ];

  home.packages = with pkgs; [
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
