# users/deepwatrcreatur/hosts/homeserver/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../.. # default config for deepwatrcreatur (up 2 levels)
    ./homeserver-justfile.nix
    ./nh.nix
    ./rbw.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-agent-ssh.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

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

  # Set home directory for Home Manager
  home.homeDirectory = "/home/deepwatrcreatur";

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true;

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
