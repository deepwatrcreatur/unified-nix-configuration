{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/gemini-cli.nix
    ../../modules/home-manager/claude-code.nix
    ../../modules/home-manager/npm.nix
    ./sops.nix
    ({ ... }: import ../../modules/home-manager/bitwarden-cli.nix {
      inherit config pkgs lib inputs;
      bwSessionSecretPath = config.sops.secrets.BW_SESSION.path;
    })
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];
}
