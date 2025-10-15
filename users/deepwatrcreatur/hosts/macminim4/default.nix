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
    cyberduck
    ffmpeg
    ghostty-bin  # Available via overlay from unstable
    input-leap
    megacmd
    obsidian
    obsidian-export
    yt-dlp
    # virt-viewer  # Linux-only, broken on macOS
  ];

  home.stateVersion = "25.11";

  home.file.".justfile".source = ./justfile; # Directly link the justfile
}
