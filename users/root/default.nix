{ config, pkgs, lib, inputs, ... }:
let
  # Path to your secrets directory
  secretsPath = toString ./secrets;
in
{
  imports = [
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/atuin.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";
  
  home.packages = with pkgs; [ sops ];
  
  programs.home-manager.enable = true;
  
  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc;
  };
  
  home.file.".config/sops/.sops.yaml" = {
    source = "${secretsPath}/sops.yaml";
    force = true;
  };
  
  # Create Bitwarden CLI directory
  home.file.".config/Bitwarden CLI/.keep".text = "";
  
  # Custom activation script that decrypts sops secrets and imports GPG keys
  home.activation.setupSecretsAndGpg = lib.hm.dag.entryAfter ["linkGeneration"] ''
    echo "=== Setting up SOPS secrets and GPG keys ==="
    
    # Ensure directories exist with proper permissions
    $DRY_RUN_CMD mkdir -p $HOME/.gnupg $HOME/.config/sops "$HOME/.config/Bitwarden CLI"
    $DRY_RUN_CMD chmod 700 $HOME/.gnupg
    $DRY_RUN_CMD chmod 755 $HOME/.config/sops "$HOME/.config/Bitwarden CLI"
    
    # Decrypt secrets using sops
    echo "Decrypting SOPS secrets..."
    
    # Decrypt GPG private key
    if $DRY_RUN_CMD test -f "${secretsPath}/gpg-private-key.asc.enc"; then
      echo "Decrypting GPG private key..."
      $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d "${secretsPath}/gpg-private-key.asc.enc" > $HOME/.gnupg/private-key.asc
      $DRY_RUN_CMD chmod 600 $HOME/.gnupg/private-key.asc
    else
      echo "Warning: GPG private key not found at ${secretsPath}/gpg-private-key.asc.enc"
    fi
    
    # Decrypt Bitwarden session
    if $DRY_RUN_CMD test -f "${secretsPath}/bitwarden.yaml"; then
      echo "Decrypting Bitwarden session..."
      $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d --extract '["BW_SESSION"]' "${secretsPath}/bitwarden.yaml" > $HOME/.config/sops/BW_SESSION
      $DRY_RUN_CMD chmod 600 $HOME/.config/sops/BW_SESSION
    else
      echo "Warning: Bitwarden secrets not found at ${secretsPath}/bitwarden.yaml"
    fi
    
    # Decrypt Bitwarden data.json
    if $DRY_RUN_CMD test -f "${secretsPath}/data.json.enc"; then
      echo "Decrypting Bitwarden data.json..."
      $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d "${secretsPath}/data.json.enc" > "$HOME/.config/Bitwarden CLI/data.json"
      $DRY_RUN_CMD chmod 600 "$HOME/.config/Bitwarden CLI/data.json"
    else
      echo "Warning: Bitwarden data.json not found at ${secretsPath}/data.json.enc"
    fi
    
    # Import GPG keys
    echo "Importing GPG keys..."
    
    # Import public key
    if $DRY_RUN_CMD test -f $HOME/.gnupg/public-key.asc; then
      echo "Importing public key..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/public-key.asc || true
    fi
    
    # Import private key
    if $DRY_RUN_CMD test -f $HOME/.gnupg/private-key.asc; then
      echo "Importing private key..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg-connect-agent /bye || true
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --pinentry-mode loopback --passphrase "" --import $HOME/.gnupg/private-key.asc || true
    fi
    
    # Set trust for the key
    echo "Setting GPG key trust..."
    $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust || true
    
    echo "=== SOPS secrets and GPG setup complete ==="
  '';
}
