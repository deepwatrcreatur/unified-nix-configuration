{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../modules/nixos/utility-packages.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    docker
    docker-compose
  ];
}
