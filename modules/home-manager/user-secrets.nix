{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.user-secrets;
in {
  options.services.user-secrets = {
    enable = mkEnableOption "User-specific SOPS secrets activation";

    secretsPath = mkOption {
      type = types.path;
      description = "Path to the user secrets directory";
    };

    agenixGithubTokenPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/agenix-user-secrets/github-token";
      description = "Path to the agenix-decrypted GitHub token, if present.";
    };

    systemAtticTokenPath = mkOption {
      type = types.str;
      default = "/run/secrets/attic-client-token";
      description = "Path to the system-provisioned attic token, if present.";
    };
  };

  config = mkIf cfg.enable {
    home.activation.userSecretsActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      export PATH="${lib.makeBinPath [pkgs.sops]}:$PATH"

      # Decrypt secrets - with error handling
      mkdir -p "$HOME/.config/sops"
      mkdir -p "$HOME/.config/git"

      SECRETS_PATH="${toString cfg.secretsPath}"
      ATTIC_TOKEN_ENC="$SECRETS_PATH/attic-client-token.yaml.enc"
      GITHUB_TOKEN_ENC="$SECRETS_PATH/github-token.txt.enc"
      AGENIX_GITHUB_TOKEN="${cfg.agenixGithubTokenPath}"
      SYSTEM_GITHUB_TOKEN="/run/secrets/github-token"
      SYSTEM_ATTIC_TOKEN="${cfg.systemAtticTokenPath}"

      if [ -f "$SYSTEM_ATTIC_TOKEN" ] && [ -r "$SYSTEM_ATTIC_TOKEN" ]; then
        install -m 600 "$SYSTEM_ATTIC_TOKEN" "$HOME/.config/sops/attic-client-token"
      elif [ -f "$ATTIC_TOKEN_ENC" ]; then
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          tmp_attic_token="$(mktemp)"
          if sops -d "$ATTIC_TOKEN_ENC" > "$tmp_attic_token" 2>/dev/null; then
            install -m 600 "$tmp_attic_token" "$HOME/.config/sops/attic-client-token"
          fi
          rm -f "$tmp_attic_token"
        else
          # echo "Warning: SOPS age key not found at $SOPS_AGE_KEY_FILE, skipping attic-client-token decryption"
          true
        fi
      else
        # echo "Warning: no system or SOPS attic-client-token source found; leaving existing token in place"
        true
      fi

      # Prefer agenix GitHub token for nix flake operations, otherwise fall back
      # to the legacy SOPS-encrypted user secret.
      if [ -f "$AGENIX_GITHUB_TOKEN" ]; then
        install -m 600 "$AGENIX_GITHUB_TOKEN" "$HOME/.config/git/github-token"
      elif [ -f "$SYSTEM_GITHUB_TOKEN" ] && [ -r "$SYSTEM_GITHUB_TOKEN" ]; then
        install -m 600 "$SYSTEM_GITHUB_TOKEN" "$HOME/.config/git/github-token"
      elif [ -f "$GITHUB_TOKEN_ENC" ]; then
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          tmp_github_token="$(mktemp)"
          if sops -d "$GITHUB_TOKEN_ENC" > "$tmp_github_token" 2>/dev/null; then
            install -m 600 "$tmp_github_token" "$HOME/.config/git/github-token"
          fi
          rm -f "$tmp_github_token"
        else
          # echo "Warning: SOPS age key not found at $SOPS_AGE_KEY_FILE, skipping github-token decryption"
          true
        fi
      else
        # echo "Warning: no agenix or SOPS GitHub token found; leaving existing github-token in place"
        true
      fi
    '';
  };
}
