{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.secrets-activation;
in
{
  # SOPS compatibility layer for hosts that still rely on ~/.config/sops and SOPS-encrypted home secrets.
  # New agenix-first hosts should prefer agenix-user-secrets and avoid enabling
  # this module unless they still need SOPS-based flows.
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

    enableGithubTokenDecryption = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to decrypt the GitHub token";
    };

    continueOnError = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to continue activation even if some operations fail";
    };
  };

  config = mkIf cfg.enable {
    # Set environment variable for all shells
    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };

    # Make sure packages are available in the environment
    home.packages = [
      pkgs.sops
      pkgs.gnupg
    ];

    # Activation script with proper store path handling
    home.activation.setupSecretsAndGpg = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      echo "=== Setting up SOPS secrets and GPG keys for ${config.home.username} ==="

      # Set SOPS environment variable explicitly (runs in bash during activation)
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      # Use PATH to find binaries instead of hardcoded store paths
      export PATH="${
        lib.makeBinPath [
          pkgs.sops
          pkgs.gnupg
        ]
      }:$PATH"

      # Verify environment setup
      echo "Debug: SOPS_AGE_KEY_FILE is set to: $SOPS_AGE_KEY_FILE"
      echo "Debug: Age key file exists: $(test -f "$SOPS_AGE_KEY_FILE" && echo "YES" || echo "NO")"

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
          if [ -n "$DRY_RUN_CMD" ]; then
            echo "DRY RUN: Would decrypt GPG private key"
          else
            tmp_gpg=$(mktemp)
            if SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d "${cfg.secretsPath}/gpg-private-key.asc.enc" > "$tmp_gpg" 2>/dev/null; then
              if [ -s "$tmp_gpg" ]; then
                mv "$tmp_gpg" $HOME/.gnupg/private-key.asc
                chmod 600 $HOME/.gnupg/private-key.asc
                echo "GPG private key decrypted successfully"
              else
                echo "Warning: Decrypted GPG private key is empty"
                rm -f "$tmp_gpg"
                ${optionalString (!cfg.continueOnError) "exit 1"}
              fi
            else
              echo "Warning: Failed to decrypt GPG private key (SOPS error)"
              rm -f "$tmp_gpg"
              ${optionalString (!cfg.continueOnError) "exit 1"}
            fi
          fi
        else
          echo "Warning: GPG private key not found at ${cfg.secretsPath}/gpg-private-key.asc.enc"
        fi
      ''}

      ${optionalString cfg.enableBitwardenDecryption ''
         # Decrypt Bitwarden session
         if [ -f "${cfg.secretsPath}/bitwarden.yaml" ]; then
          echo "Decrypting Bitwarden session..."
          if [ -n "$DRY_RUN_CMD" ]; then
            echo "DRY RUN: Would decrypt Bitwarden session"
          else
            tmp_bw=$(mktemp)
            if SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d --extract '["BW_SESSION"]' "${cfg.secretsPath}/bitwarden.yaml" > "$tmp_bw" 2>/dev/null; then
              if [ -s "$tmp_bw" ]; then
                mv "$tmp_bw" $HOME/.config/sops/BW_SESSION
                chmod 600 $HOME/.config/sops/BW_SESSION
                echo "Bitwarden session decrypted successfully"
              else
                echo "Warning: Decrypted Bitwarden session is empty"
                rm -f "$tmp_bw"
                ${optionalString (!cfg.continueOnError) "exit 1"}
              fi
            else
              echo "Warning: Failed to decrypt Bitwarden session (SOPS error)"
              rm -f "$tmp_bw"
              ${optionalString (!cfg.continueOnError) "exit 1"}
            fi
          fi
        else
          echo "Warning: Bitwarden secrets not found at ${cfg.secretsPath}/bitwarden.yaml"
        fi

        # Decrypt Bitwarden data.json
        if [ -f "${cfg.secretsPath}/data.json.enc" ]; then
          echo "Decrypting Bitwarden data.json..."
          if [ -n "$DRY_RUN_CMD" ]; then
            echo "DRY RUN: Would decrypt Bitwarden data.json"
          else
            tmp_data=$(mktemp)
            if SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d "${cfg.secretsPath}/data.json.enc" > "$tmp_data" 2>/dev/null; then
              if [ -s "$tmp_data" ]; then
                mv "$tmp_data" "$HOME/.config/Bitwarden CLI/data.json"
                chmod 600 "$HOME/.config/Bitwarden CLI/data.json"
                echo "Bitwarden data.json decrypted successfully"
              else
                echo "Warning: Decrypted Bitwarden data.json is empty"
                rm -f "$tmp_data"
                ${optionalString (!cfg.continueOnError) "exit 1"}
              fi
            else
              echo "Warning: Failed to decrypt Bitwarden data.json (SOPS error)"
              rm -f "$tmp_data"
              ${optionalString (!cfg.continueOnError) "exit 1"}
            fi
          fi
        else
          echo "Warning: Bitwarden data.json not found at ${cfg.secretsPath}/data.json.enc"
        fi
      ''}

      ${optionalString cfg.enableGithubTokenDecryption ''
        # Decrypt GitHub token
        if [ -f "${cfg.secretsPath}/github-token.txt.enc" ]; then
          echo "Decrypting GitHub token..."
          if [ -n "$DRY_RUN_CMD" ]; then
            echo "DRY RUN: Would decrypt GitHub token"
          else
            # Ensure the target directory exists
            mkdir -p "$HOME/.config/git"
            
            # Decrypt to a temporary file first to avoid overwriting with error text
            tmp_token=$(mktemp)
            if SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d "${cfg.secretsPath}/github-token.txt.enc" > "$tmp_token" 2>/dev/null; then
              # Sanity check: token should be one line, no whitespace
              if [ -s "$tmp_token" ] && [ "$(${pkgs.coreutils}/bin/wc -l < "$tmp_token")" -le 1 ] && ! ${pkgs.gnugrep}/bin/grep -q '[[:space:]]' "$tmp_token"; then
                mv "$tmp_token" "$HOME/.config/git/github-token"
                chmod 600 "$HOME/.config/git/github-token"
                echo "GitHub token decrypted successfully"
              else
                echo "Warning: Decrypted GitHub token failed sanity check (empty, multiline, or contains whitespace)"
                rm -f "$tmp_token"
                ${optionalString (!cfg.continueOnError) "exit 1"}
              fi
            else
              echo "Warning: Failed to decrypt GitHub token (SOPS error)"
              rm -f "$tmp_token"
              ${optionalString (!cfg.continueOnError) "exit 1"}
            fi
          fi
        else
          echo "Warning: GitHub token not found at ${cfg.secretsPath}/github-token.txt.enc"
        fi
      ''}

      # Import GPG keys
      echo "Importing GPG keys..."

      # Import public key
      if [ -f $HOME/.gnupg/public-key.asc ]; then
        echo "Importing public key..."
        $DRY_RUN_CMD gpg --import $HOME/.gnupg/public-key.asc || true
      fi

      # Import private key
      if [ -f $HOME/.gnupg/private-key.asc ]; then
        echo "Importing private key..."
        $DRY_RUN_CMD gpg-connect-agent /bye || true
        $DRY_RUN_CMD gpg --batch --pinentry-mode loopback --passphrase "" --import $HOME/.gnupg/private-key.asc || true
      fi

      # Set trust for the key
      echo "Setting GPG key trust..."
      $DRY_RUN_CMD echo "${cfg.gpgKeyId}:6:" | gpg --import-ownertrust || true

      echo "=== SOPS secrets and GPG setup complete for ${config.home.username} ==="
      ${optionalString cfg.continueOnError "exit 0"}
    '';
  };
}
