{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    yt-dlp
    virt-viewer
  ];

}
