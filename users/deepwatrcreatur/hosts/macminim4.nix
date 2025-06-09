{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
    ../xbar.nix
  ];

  home.packages = with pkgs; [
    rclone
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
