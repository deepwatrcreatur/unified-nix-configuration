{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/secrets-activation.nix
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  programs.rclone.enable = true;

  home.file.".config/rclone/filter.txt" = {
    source = ./rclone-filter.txt;
  };

  home.username = "deepwatrcreatur";

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
    enableBitwardenDecryption = false;  # Handled by sops-nix
    enableGpgKeyDecryption = true;
  };
}
