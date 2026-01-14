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
  xdg.configFile."fnox/fnox.toml" = lib.mkIf (pkgs ? fnox) {
    text = ''
      [providers.age]
      type = "age"
      recipients = [
        "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr",
        "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz"
      ]

      [secrets.GITHUB_TOKEN]
      description = "GitHub Personal Access Token"

      [secrets.GROK_API_KEY]
      description = "XAI Grok API Key"

      [secrets.BW_SESSION]
      description = "Bitwarden Session Key"

      [secrets.ATTIC_CLIENT_JWT_TOKEN]
      description = "Attic Client JWT Token"

      [secrets.OPENCODE_ZEN_API_KEY]
      description = "OpenCode Zen API Key"

      [secrets.Z_AI_API_KEY]
      description = "Z.AI API Key"

      # We define the secret structure, but the value must be set manually
      # or migrated by the user using `fnox set <SECRET> <value>`
      [secrets.GITHUB_TOKEN.default]
      provider = "age"

      [secrets.GROK_API_KEY.default]
      provider = "age"

      [secrets.BW_SESSION.default]
      provider = "age"

      [secrets.ATTIC_CLIENT_JWT_TOKEN.default]
      provider = "age"

      [secrets.OPENCODE_ZEN_API_KEY.default]
      provider = "age"

      [secrets.Z_AI_API_KEY.default]
      provider = "age"
    '';
  };

  # Shell integration intentionally disabled.
  #
  # Some fnox builds do not provide a `fnox env` subcommand. We rely on explicit
  # wrappers (e.g. `gh-fnox`, `opencode-zai`) to fetch only the secrets needed
  # for that command via `fnox get ...`.
}
