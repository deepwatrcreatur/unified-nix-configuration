{ lib, ... }:
{
  imports = [
    ../gateway/configuration.nix
  ];

  home-manager.users.deepwatrcreatur.imports = lib.mkForce [
    ../../../modules/home-manager/git.nix
    ../../../modules/home-manager/gpg-cli.nix
    ../../../users/deepwatrcreatur/hosts/router
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router";

  services.router-homelab.sshTarget = lib.mkForce "ssh router.deepwatercreature.com";
}
