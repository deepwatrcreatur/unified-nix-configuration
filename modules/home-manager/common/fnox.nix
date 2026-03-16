{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = lib.optionals (inputs ? fnox) [ inputs.fnox.homeManagerModules.default ];

  config =
    {
      home.packages = lib.optionals (pkgs ? opencode) [ pkgs.opencode ];
    }
    // lib.optionalAttrs (inputs ? fnox) {
      programs.fnox = {
        enable = true;
        recipients = [
          "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr"
          "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz"
        ];

        seedSecretSources = {
          GITHUB_TOKEN = [
            "${config.home.homeDirectory}/.config/git/github-token"
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/github-token"
            "/run/agenix/github-token-agenix"
          ];
          GROK_API_KEY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/grok-api-key"
            "/run/agenix/grok-api-key"
          ];
          Z_AI_API_KEY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/z-ai-api-key"
            "/run/agenix/z-ai-api-key"
          ];
          OPENCODE_ZEN_API_KEY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/opencode-zen-api-key"
            "/run/agenix/opencode-zen-api-key"
          ];
          OPENROUTER_API_KEY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/openrouter-api-key"
            "/run/agenix/openrouter-api-key"
          ];
          ATTIC_CLIENT_JWT_TOKEN = [
            "${config.home.homeDirectory}/.config/sops/attic-client-token"
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/attic-client-token"
            "/run/agenix/attic-client-token"
          ];
          PROXMOX_API_TOKEN = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/proxmox-api-token"
            "/run/agenix/proxmox-api-token"
          ];
        };
      };
    };
}
