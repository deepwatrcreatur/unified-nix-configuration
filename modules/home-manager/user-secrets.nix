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
    enable = mkEnableOption "User-specific secrets activation";

    migrationMode = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable SOPS fallback/migration logic.
        Disable this for hosts that are fully migrated to agenix.
      '';
    };

    secretsPath = mkOption {
      type = types.path;
      description = "Path to the user secrets directory (for SOPS migration)";
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
      # Compatibility layer: prefer agenix and system tokens first; SOPS CLI is
      # only used as a final fallback for hosts that still ship legacy
      # ~/.config/sops secrets.
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
      USER_GITHUB_TOKEN="$HOME/.config/git/github-token"

      token_file_is_sane() {
        local token_file="$1"
        local line_count

        [ -f "$token_file" ] || return 1
        [ -r "$token_file" ] || return 1

        # Refuse empty, multiline, or whitespace-containing content so failed
        # decrypt output does not masquerade as a usable GitHub token.
        [ -s "$token_file" ] || return 1
        line_count="$(${pkgs.coreutils}/bin/wc -l < "$token_file")"
        [ "$line_count" -le 1 ] || return 1
        ${pkgs.gnugrep}/bin/grep -q '[[:space:]]' "$token_file" && return 1

        return 0
      }

      install_github_token_if_sane() {
        local source_file="$1"

        if token_file_is_sane "$source_file"; then
          install -m 600 "$source_file" "$USER_GITHUB_TOKEN"
          return $?
        fi

        return 1
      }

      if [ -f "$SYSTEM_ATTIC_TOKEN" ] && [ -r "$SYSTEM_ATTIC_TOKEN" ]; then
        install -m 600 "$SYSTEM_ATTIC_TOKEN" "$HOME/.config/sops/attic-client-token"
      elif [ "${if cfg.migrationMode then "1" else "0"}" = "1" ] && [ -f "$ATTIC_TOKEN_ENC" ]; then
        # LEGACY SOPS MIGRATION PATH
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          tmp_attic_token="$(mktemp)"
          if sops -d "$ATTIC_TOKEN_ENC" > "$tmp_attic_token" 2>/dev/null; then
            install -m 600 "$tmp_attic_token" "$HOME/.config/sops/attic-client-token"
          fi
          rm -f "$tmp_attic_token"
        fi
      fi

      # Prefer agenix GitHub token for nix flake operations, then fall back to
      # system and finally the legacy SOPS-encrypted user secret. Invalid
      # higher-priority sources must not block lower-priority fallbacks.
      github_token_installed=0

      if [ -f "$AGENIX_GITHUB_TOKEN" ]; then
        if install_github_token_if_sane "$AGENIX_GITHUB_TOKEN"; then
          github_token_installed=1
        else
          echo "Warning: refusing invalid agenix GitHub token at $AGENIX_GITHUB_TOKEN" >&2
        fi
      fi

      if [ "$github_token_installed" -eq 0 ] && [ -f "$SYSTEM_GITHUB_TOKEN" ] && [ -r "$SYSTEM_GITHUB_TOKEN" ]; then
        if install_github_token_if_sane "$SYSTEM_GITHUB_TOKEN"; then
          github_token_installed=1
        else
          echo "Warning: refusing invalid system GitHub token at $SYSTEM_GITHUB_TOKEN" >&2
        fi
      fi

      if [ "$github_token_installed" -eq 0 ] && [ "${if cfg.migrationMode then "1" else "0"}" = "1" ] && [ -f "$GITHUB_TOKEN_ENC" ]; then
        # LEGACY SOPS MIGRATION PATH
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          tmp_github_token="$(mktemp)"
          if sops -d "$GITHUB_TOKEN_ENC" > "$tmp_github_token" 2>/dev/null; then
            if install_github_token_if_sane "$tmp_github_token"; then
              github_token_installed=1
            else
              echo "Warning: refusing invalid decrypted GitHub token from $GITHUB_TOKEN_ENC" >&2
            fi
          fi
          rm -f "$tmp_github_token"
        fi
      fi

      # If no valid source was installed this run, drop obviously invalid stale
      # content so shells and flake operations do not keep exporting garbage.
      if [ -f "$USER_GITHUB_TOKEN" ] && ! token_file_is_sane "$USER_GITHUB_TOKEN"; then
        rm -f "$USER_GITHUB_TOKEN"
        echo "Warning: removed invalid GitHub token file at $USER_GITHUB_TOKEN" >&2
      fi
    '';
  };
}
