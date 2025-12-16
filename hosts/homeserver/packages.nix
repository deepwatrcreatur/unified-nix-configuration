{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    compose2nix
    docker
    docker-compose
    vim
    wget
    curl
    git
    htop
  ];
}
