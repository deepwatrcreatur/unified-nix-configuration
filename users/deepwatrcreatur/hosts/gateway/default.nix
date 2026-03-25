{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../../../modules/home-manager/default.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  # User-scoped secrets decrypted via age
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

  # Disable user-level netrc - NixOS uses system-level /run/nix/nix-ci-netrc
  services.nix-user-config.netrcMachine = null;

  home.stateVersion = "25.11";
}
