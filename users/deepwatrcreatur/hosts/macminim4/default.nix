{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../../modules/home-manager/ghostty
    ../../xbar.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    jq
    yq    
    rclone
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

}
