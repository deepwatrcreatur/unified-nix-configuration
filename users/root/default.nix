{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/atuin.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager/secrets-activation.nix
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [ sops ];
  programs.home-manager.enable = true;
  
  # Configure secrets activation
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ./secrets;
    continueOnError = true;  # Be more forgiving for root
    enableBitwardenDecryption = true;
    enableGpgKeyDecryption = true;
  };
  
  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc;
  };
  home.file.".config/sops/.sops.yaml" = {
    source = "${toString ./secrets}/sops.yaml";
    force = true;
  };
  home.file.".config/Bitwarden CLI/.keep".text = "";
}
