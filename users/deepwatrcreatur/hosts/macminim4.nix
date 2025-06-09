{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
  ];

  home.packages = with pkgs; [
    xbar
    rclone
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
