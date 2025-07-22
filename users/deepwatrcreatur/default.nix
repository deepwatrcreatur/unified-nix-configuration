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

  home.file.".gnupg/public-key.asc" = {
    source = toString ./gpg-public-key.asc; # Use absolute path
    onChange = ''
      echo "Placed $HOME/.gnupg/public-key.asc from ${toString ./gpg-public-key.asc}"
      ls -l $HOME/.gnupg/public-key.asc
    '';
  };
        
  # Import GPG keys during activation
  home.activation.importGpgKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
      echo "Importing private key"
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/private-key.asc
    else
      echo "Error: $HOME/.gnupg/private-key.asc not found"
      exit 1
    fi

    echo "Setting trust for EF1502C27653693B"
    $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
  '';
}
