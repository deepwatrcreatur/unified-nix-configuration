{ config, pkgs, ... }:

{
  imports = [
    ../../../../modules/home-manager/rclone.nix
    ../../../../modules/home-manager/ghostty
    #../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/gpg-mac.nix
    ../../../../modules/home-manager/env-darwin.nix
    ./karabiner.nix
    ../../xbar.nix
    ../../rbw.nix
  ];

  home.packages = with pkgs; [
    bitwarden
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];
}
