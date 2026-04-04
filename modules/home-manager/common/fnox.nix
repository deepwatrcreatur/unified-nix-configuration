{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  fnoxLib =
    if inputs ? fnox then
      import (inputs.fnox + "/lib/default.nix") { inherit lib pkgs; }
    else
      null;
in
{
  imports = lib.optionals (inputs ? fnox) [ inputs.fnox.homeManagerModules.default ];

  config = lib.optionalAttrs (inputs ? fnox) {
      programs.fnox = {
        enable = true;
        recipients = [
          "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr"
          "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz"
        ];

        seedSecretSources = {
          BW_SESSION = [
            "${config.home.homeDirectory}/.config/sops/BW_SESSION"
          ];
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
            "/run/secrets/attic-client-token"
            "/run/agenix/attic-client-token"
          ];
          PROXMOX_API_TOKEN = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/proxmox-api-token"
            "/run/agenix/proxmox-api-token"
          ];
          PBS_PASSWORD = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/pbs-password"
            "/run/agenix/pbs-password"
          ];
          PBS_REPOSITORY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/pbs-repository"
            "/run/agenix/pbs-repository"
          ];
          FACTORY_API_KEY = [
            "${config.home.homeDirectory}/.local/share/agenix-user-secrets/factory-api-key"
            "/run/agenix/factory-api-key"
          ];
        };

        # This repo provides its own gh/bw/droid/pbs wrappers that expose the
        # canonical command names in addition to `*-fnox`. Drop fnox's
        # default ones to avoid duplicate home.packages entries.
        wrappedCommands = lib.mkDefault (
          lib.removeAttrs
            (fnoxLib.defaultWrappedCommandSpecs { inherit pkgs; })
            [
              "gh-fnox"
              "bw-fnox"
              "factory-droid-fnox"
              "proxmox-backup-client-fnox"
            ]
        );
      };
    };
}
