{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
  ];

  home.packages = with pkgs; [
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
