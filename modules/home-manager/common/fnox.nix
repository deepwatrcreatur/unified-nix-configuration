{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.fnox.homeManagerModules.default ];

  config = lib.mkIf (pkgs ? fnox) {
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
        PROXMOX_API_TOKEN = [
          "${config.home.homeDirectory}/.local/share/agenix-user-secrets/proxmox-api-token"
          "/run/agenix/proxmox-api-token"
        ];
      };
    };

    # Keep plain opencode installed in addition to the fnox-backed wrappers.
    home.packages = lib.optionals (pkgs ? opencode) [ pkgs.opencode ];
  };
}
