{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nix-inspect
    compose2nix
    docker
    docker-compose
    vim
    wget
    curl
    git
    htop
    nh
  ];
}
