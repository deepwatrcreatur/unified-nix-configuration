{ config, pkgs, mac-app-util, ... }:

{
  imports = [
    ../../default.nix  # Import main user config (includes SSH keys and common modules)
    mac-app-util.homeManagerModules.default
    ../../../../modules/home-manager/ghostty
    #../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/gpg-mac.nix
    ../../../../modules/home-manager/env-darwin.nix
    ./nh.nix
    ./karabiner.nix
    ../../xbar.nix
    ../../rbw.nix
  ];

  home.packages = with pkgs; [
    bitwarden
    megacmd
    ffmpeg
    ghostty-bin  # Available via overlay from unstable
    input-leap
    yt-dlp
    virt-viewer
  ];

  home.stateVersion = "25.11";

  myModules.just = {
    enable = true;
    hostname = "macminim4";
  };
  programs.attic-client.enable = true;
}
