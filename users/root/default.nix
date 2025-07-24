{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/atuin.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ./sops.nix
  
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];

  programs.home-manager.enable = true;
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
      echo "Error: $HOME/.gnupg/private-key.asc not found"
      exit 1
    fi

    echo "Setting trust for EF1502C27653693B"
    $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
  '';
}

