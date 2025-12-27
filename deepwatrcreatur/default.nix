{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/secrets-activation.nix
    ../../modules/home-manager/user-secrets.nix
    ./sops.nix
    ./rbw.nix
    ./env.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone-scripts.nix
    ../../modules/home-manager
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  programs.rclone-scripts.secretsPath = ./secrets;

  services.user-secrets = {
    enable = true;
    secretsPath = ./secrets;
  };

  home.username = "deepwatrcreatur";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc; # Remove toString, just use the path directly
  };
}
