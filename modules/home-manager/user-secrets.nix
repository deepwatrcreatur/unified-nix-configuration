{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.user-secrets;
in
{
  options.services.user-secrets = {
    enable = mkEnableOption "User-specific SOPS secrets activation";

    secretsPath = mkOption {
      type = types.path;
      description = "Path to the user secrets directory";
    };
  };

  config = mkIf cfg.enable {
    home.activation.userSecretsActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

      # Decrypt secrets - with error handling
      mkdir -p "$HOME/.config/sops"
      mkdir -p "$HOME/.config/git"

      SECRETS_PATH="${toString cfg.secretsPath}"
      ATTIC_TOKEN_ENC="$SECRETS_PATH/attic-client-token.yaml.enc"
      GITHUB_TOKEN_ENC="$SECRETS_PATH/github-token.txt.enc"

      if [ -f "$ATTIC_TOKEN_ENC" ]; then
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          sops -d "$ATTIC_TOKEN_ENC" > "$HOME/.config/sops/attic-client-token" 2>/dev/null && chmod 600 "$HOME/.config/sops/attic-client-token" || true
        else
          echo "Warning: SOPS age key not found at $SOPS_AGE_KEY_FILE, skipping attic-client-token decryption"
        fi
      else
        echo "Warning: attic-client-token.yaml.enc not found at $ATTIC_TOKEN_ENC, skipping decryption"
      fi

      # Decrypt github-token for nix flake operations
      if [ -f "$GITHUB_TOKEN_ENC" ]; then
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          sops -d "$GITHUB_TOKEN_ENC" > "$HOME/.config/git/github-token" 2>/dev/null && chmod 600 "$HOME/.config/git/github-token" || true
        else
          echo "Warning: SOPS age key not found at $SOPS_AGE_KEY_FILE, skipping github-token decryption"
        fi
      else
        echo "Warning: github-token.txt.enc not found at $GITHUB_TOKEN_ENC, skipping github token setup"
      fi
    '';
  };
}