{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/gemini-cli.nix
    ../../modules/home-manager/npm.nix
    ../../modules/home-manager/env.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone.nix
    ../../modules/home-manager/atuin.nix
  ];
  
  programs.bitwarden-cli = {
    enable = true;
  };

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  # Import GPG keys during activation
  home.activation.importGpgKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.gnupg
    $DRY_RUN_CMD chmod 700 $HOME/.gnupg
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/public-key.asc || true
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/private-key.asc || true
    $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust || true
  '';
}
