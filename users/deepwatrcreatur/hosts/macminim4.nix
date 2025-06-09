{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
  ];

  home.packages = with pkgs; [
    xbar
    rclone
    rclone-rclone-browser
    rclone-ui
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
