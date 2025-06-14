{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nh
    nushell
    fzf
    yazi
    htop
    btop
    gitAndTools.gh
    wget
    curl
    iperf3
    age
    oh-my-posh
    tmux
    nmap
    bat
    nix-inspect
    compose2nix
    docker
    nodejs_20
    rsync
    elixir
    erlang
    docker-compose
  ];
}
