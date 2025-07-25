{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.secrets-activation;
in
{
  options.services.secrets-activation = {
    enable = mkEnableOption "SOPS secrets and GPG key activation";
    
    secretsPath = mkOption {
      type = types.str;
      description = "Path to the secrets directory";
    };
    
    gpgKeyId = mkOption {
      type = types.str;
      default = "A116F3E1C37D5592D940BF05EF1502C27653693B";
      description = "GPG key ID for trust setting";
    };
    
    enableBitwardenDecryption = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to decrypt Bitwarden secrets";
    };
    
    enableGpgKeyDecryption = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to decrypt GPG private key";
    };
    
    continueOnError = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to continue activation even if some operations fail";
    };
  };

  config = mkIf cfg.enable {
    home.activation.setupSecretsAndGpg = lib.hm.dag.entryAfter ["linkGeneration"] ''
      echo "=== Setting up SOPS secrets and GPG keys for ${config.home.username} ==="
      
      ${optionalString cfg.continueOnError "set +e"}
      
      # Ensure directories exist with proper permissions
      $DRY_RUN_CMD mkdir -p $HOME/.gnupg $HOME/.config/sops "$HOME/.config/Bitwarden CLI"
      $DRY_RUN_CMD chmod 700 $HOME/.gnupg
      $DRY_RUN_CMD chmod 755 $HOME/.config/sops "$HOME/.config/Bitwarden CLI"
      
      # Check if secrets directory exists before proceeding
      if [ ! -d "${cfg.secretsPath}" ]; then
        echo "Warning: Secrets directory ${cfg.secretsPath} does not exist. Skipping secret decryption."
        ${if cfg.continueOnError then "exit 0" else "exit 1"}
      fi
      
      echo "Using secrets from: ${cfg.secretsPath}"
      
      ${optionalString cfg.enableGpgKeyDecryption ''
        # Decrypt GPG private key
        if [ -f "${cfg.secretsPath}/gpg-private-key.asc.enc" ]; then
          echo "Decrypting GPG private key..."
          if $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d "${cfg.secretsPath}/gpg-private-key.asc.enc" > $HOME/.gnupg/private-key.asc 2>/dev/null; then
            $DRY_RUN_CMD chmod 600 $HOME/.gnupg/private-key.asc
            echo "GPG private key decrypted successfully"
          else
            echo "Warning: Failed to decrypt GPG private key"
            ${optionalString (!cfg.continueOnError) "exit 1"}
          fi
        else
          echo "Warning: GPG private key not found at ${cfg.secretsPath}/gpg-private-key.asc.enc"
        fi
      ''}
      
      ${optionalString cfg.enableBitwardenDecryption ''
        # Decrypt Bitwarden session
        if [ -f "${cfg.secretsPath}/bitwarden.yaml" ]; then
          echo "Decrypting Bitwarden session..."
          if $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d --extract '["BW_SESSION"]' "${cfg.secretsPath}/bitwarden.yaml" > $HOME/.config/sops/BW_SESSION 2>/dev/null; then
            $DRY_RUN_CMD chmod 600 $HOME/.config/sops/BW_SESSION
            echo "Bitwarden session decrypted successfully"
          else
            echo "Warning: Failed to decrypt Bitwarden session"
            ${optionalString (!cfg.continueOnError) "exit 1"}
          fi
        else
          echo "Warning: Bitwarden secrets not found at ${cfg.secretsPath}/bitwarden.yaml"
        fi
        
        # Decrypt Bitwarden data.json
        if [ -f "${cfg.secretsPath}/data.json.enc" ]; then
          echo "Decrypting Bitwarden data.json..."
          if $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d "${cfg.secretsPath}/data.json.enc" > "$HOME/.config/Bitwarden CLI/data.json" 2>/dev/null; then
            $DRY_RUN_CMD chmod 600 "$HOME/.config/Bitwarden CLI/data.json"
            echo "Bitwarden data.json decrypted successfully"
          else
            echo "Warning: Failed to decrypt Bitwarden data.json"
            ${optionalString (!cfg.continueOnError) "exit 1"}
          fi
        else
          echo "Warning: Bitwarden data.json not found at ${cfg.secretsPath}/data.json.enc"
        fi
      ''}
      
      # Import GPG keys
      echo "Importing GPG keys..."
      
      # Import public key
      if [ -f $HOME/.gnupg/public-key.asc ]; then
        echo "Importing public key..."
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/public-key.asc || true
      fi
      
      # Import private key
      if [ -f $HOME/.gnupg/private-key.asc ]; then
        echo "Importing private key..."
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg-connect-agent /bye || true
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --pinentry-mode loopback --passphrase "" --import $HOME/.gnupg/private-key.asc || true
      fi
      
      # Set trust for the key
      echo "Setting GPG key trust..."
      $DRY_RUN_CMD echo "${cfg.gpgKeyId}:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust || true
      
      echo "=== SOPS secrets and GPG setup complete for ${config.home.username} ==="
      ${optionalString cfg.continueOnError "exit 0"}
    '';
  };
}
