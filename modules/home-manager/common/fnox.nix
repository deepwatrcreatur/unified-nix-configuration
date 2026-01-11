{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Configure fnox environment variables
  home.sessionVariables = {
    # Point fnox to the sops age key
    FNOX_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Create fnox configuration
  xdg.configFile."fnox/fnox.toml".text = ''
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
  '';

  # Shell integration to load secrets
  programs.bash.initExtra = ''
    if command -v fnox &> /dev/null; then
      eval "$(fnox env)"
    fi
  '';

  programs.zsh.initContent = ''
    if command -v fnox &> /dev/null; then
      eval "$(fnox env)"
    fi
  '';

  programs.fish.interactiveShellInit = ''
    if command -v fnox &> /dev/null
      fnox env | source
    end
  '';
  
  programs.nushell.extraConfig = ''
    if (which fnox | is-not-empty) {
      fnox env | load-env
    }
  '';
}
