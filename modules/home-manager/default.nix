# modules/home-manager/default.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./env.nix # shell environment settings
    ./nushell.nix
    ./helix
    ./fish.nix
    ./jujutsu
    ./starship.nix
    ./cargo-binstall.nix
    ./yazelix.nix
    ./npm.nix
    ./eza.nix 
    ./fzf.nix
    ./shell-aliases.nix
    ./sshs.nix
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
    nmap
    yamllint
    file
    lsd
    bat
    tmux
    neovim
    python3
    glow
    ripgrep
    age
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };

  home.file.".ssh/config".source = ./ssh-config;
  
  programs.home-manager.enable = true;
}
