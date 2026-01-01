{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../modules/common/utility-packages.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    docker
    docker-compose
  ];
}
