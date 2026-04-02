{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../default.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  # Keep router-backup user profile aligned with main router.
  services.agenix-user-secrets = {
    enable = true;
    secrets = {
      github-token = {
        source = ../../../../secrets-agenix/github-token.age;
        target = ".local/share/agenix-user-secrets/github-token";
        extraTargets = [ ".config/git/github-token" ];
      };
    };
  };

  services.nix-user-config.netrcMachine = null;

  home.stateVersion = "25.11";
}
