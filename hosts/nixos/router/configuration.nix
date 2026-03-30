{ lib, ... }:
{
  imports = [
    ../gateway/configuration.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router";

  services.router-homelab.sshTarget = lib.mkForce "ssh router.deepwatercreature.com";
}
