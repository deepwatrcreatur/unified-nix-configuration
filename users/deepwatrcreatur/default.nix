{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
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

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc;  # Remove toString, just use the path directly
  };

  # Import GPG keys during activation (after files are linked and sops secrets are available)
  home.activation.importGpgKeys = lib.hm.dag.entryAfter ["linkGeneration" "setupSecrets"] ''
    echo "Creating ~/.gnupg directory"
    $DRY_RUN_CMD mkdir -p $HOME/.gnupg
    $DRY_RUN_CMD chmod 700 $HOME/.gnupg

    echo "Checking for public-key.asc"
    if [ -f $HOME/.gnupg/public-key.asc ]; then
      echo "Importing public key"
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/public-key.asc
    else
      echo "Error: $HOME/.gnupg/public-key.asc not found"
      exit 1
    fi

    echo "Checking for private-key.asc"
    if [ -f $HOME/.gnupg/private-key.asc ]; then
      echo "Starting GPG agent if needed"
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg-connect-agent /bye || true
      
      echo "Importing private key (batch mode, no agent)"
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --pinentry-mode loopback --passphrase "" --import $HOME/.gnupg/private-key.asc
    else
      # Check if we're on macOS and make it a warning instead of error
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Warning: $HOME/.gnupg/private-key.asc not found on macOS - skipping private key import"
        echo "Note: sops-nix age key file discovery issue on macOS"
      else
        echo "Error: $HOME/.gnupg/private-key.asc not found"
        exit 1
      fi
    fi

    echo "Setting trust for EF1502C27653693B"
    $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
  '';
}
