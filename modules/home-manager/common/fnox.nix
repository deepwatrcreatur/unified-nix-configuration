{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Configure fnox environment variables (only if fnox package is available)
  home.sessionVariables = lib.mkIf (pkgs ? fnox) {
    # Point fnox to the sops age key
    FNOX_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home.packages = lib.optionals (pkgs ? fnox) (
    [ pkgs.fnox ]
    ++ lib.optionals (pkgs ? opencode-zai) [ pkgs.opencode-zai ]
    ++ lib.optionals (pkgs ? opencode-claude) [ pkgs.opencode-claude ]
    ++ lib.optionals (pkgs ? gh-fnox) [ pkgs.gh-fnox ]
    ++ lib.optionals (pkgs ? bw-fnox) [ pkgs.bw-fnox ]
  );

  # Create fnox configuration (only if fnox package is available)
  # NOTE: fnox reads its global config from ~/.config/fnox/config.toml
  xdg.configFile."fnox/config.toml" = lib.mkIf (pkgs ? fnox) {
    text = ''
      [providers.age]
      type = "age"
      recipients = [
        "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr",
        "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz"
      ]

      [secrets.GITHUB_TOKEN]
      description = "GitHub Personal Access Token"
      default = "age"

      [secrets.GROK_API_KEY]
      description = "XAI Grok API Key"
      default = "age"

      [secrets.BW_SESSION]
      description = "Bitwarden Session Key"
      default = "age"

      [secrets.ATTIC_CLIENT_JWT_TOKEN]
      description = "Attic Client JWT Token"
      default = "age"

      [secrets.OPENCODE_ZEN_API_KEY]
      description = "OpenCode Zen API Key"
      default = "age"

      [secrets.Z_AI_API_KEY]
      description = "Z.AI API Key"
      default = "age"
    '';
  };

  # Seed fnox secrets from sops-nix (if present).
  # This keeps wrappers working without injecting secrets into every shell.
  home.activation.fnoxSeedFromSops = lib.mkIf (pkgs ? fnox) (
    lib.hm.dag.entryAfter [ "sops-nix" ] ''
        if ! command -v fnox >/dev/null 2>&1; then
          return 0
        fi

        export FNOX_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
        export FNOX_CONFIG="$HOME/.config/fnox/config.toml"

        seed_secret() {
          name="$1"
          file="$2"

          if [ -z "$file" ] || [ ! -f "$file" ]; then
            return 0
          fi

          if fnox -c "$FNOX_CONFIG" get "$name" >/dev/null 2>&1; then
            return 0
          fi

          value="$(cat "$file" 2>/dev/null || true)"
          if [ -z "$value" ]; then
            return 0
          fi

          fnox -c "$FNOX_CONFIG" set "$name" "$value" >/dev/null 2>&1 || true
        }

      seed_secret GITHUB_TOKEN "${config.sops.secrets."github-token".path or ""}"
      seed_secret GROK_API_KEY "${config.sops.secrets."grok-api-key".path or ""}"
      seed_secret Z_AI_API_KEY "${config.sops.secrets."z-ai-api-key".path or ""}"
      seed_secret OPENCODE_ZEN_API_KEY "${config.sops.secrets."opencode-zen-api-key".path or ""}"

    ''
  );

  # Shell integration intentionally disabled.
  #
  # Some fnox builds do not provide a `fnox env` subcommand. We rely on explicit
  # wrappers (e.g. `gh-fnox`, `opencode-zai`) to fetch only the secrets needed
  # for that command via `fnox get ...`.
}
