# modules/home-manager/default.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./env # shell environment settings
    ./nushell
    ./helix
    ./fish-shared.nix
    ./jujutsu
    ./starship.nix
    ./cargo-binstall.nix
    ./yazelix.nix
  ];

  home.packages = with pkgs; [
    wget
    curl
    xh
    fastfetch
    nmap
    htop
    btop
    rsync
    iperf3
    fish
    nushell
    lsd
    bat
    fzf
    neovim
    python3
    glow
    just
    ripgrep
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };

  home.file.".ssh/config".source = ./ssh-config;
  
  programs.home-manager.enable = true;
}
