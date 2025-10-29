{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nix-inspect
    compose2nix
    docker
    docker-compose
  ];
}
