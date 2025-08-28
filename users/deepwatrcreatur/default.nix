{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/secrets-activation.nix
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone.nix
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.file.force = true;

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc;  # Remove toString, just use the path directly
  };
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ./secrets;
    continueOnError = false;  # Be stricter for regular user
    enableBitwardenDecryption = true;
    enableGpgKeyDecryption = true;
  };
}
