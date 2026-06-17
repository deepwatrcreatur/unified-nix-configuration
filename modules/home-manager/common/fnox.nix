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
    ANTHROPIC_API_KEY = [
      "${config.home.homeDirectory}/.local/share/agenix-user-secrets/anthropic-api-key"
      "/run/agenix/anthropic-api-key"
    ];
    DEEPSEEK_API_KEY = [
      "${config.home.homeDirectory}/.local/share/agenix-user-secrets/deepseek-api-key"
      "/run/agenix/deepseek-api-key"
    ];
  };
in
{
  imports = lib.optionals (inputs ? fnox) [ inputs.fnox.homeManagerModules.default ];

  config = lib.mkIf (inputs ? fnox) (lib.mkMerge [
    {
      programs.fnox = {
        enable = lib.mkDefault pkgs.stdenv.isLinux;
      };
    }

    (lib.mkIf config.programs.fnox.enable {
      programs.fnox = {
        recipients = [
          "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr"
          "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz"
        ];

        # Seed through a writable copy of config.toml in a repo-managed
        # activation step below; the upstream activation writes after
        # linkGeneration and would otherwise hit the immutable store symlink.
        seedSecretSources = lib.mkForce { };

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
              # repo-managed opencode-zai wraps pkgs.llm-agents.opencode instead
              # of the fnox-flake's own pinned version, keeping the overlay version active
              "opencode-zai"
            ]
          );
      };

      home.activation.fnoxSeedSecretsWritable = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        target="${config.xdg.configHome}/${config.programs.fnox.configRelativePath}"
        tmp_config="$(mktemp)"
        cleanup() {
          rm -f "$tmp_config"
        }
        trap cleanup EXIT

        mkdir -p "$(dirname "$target")"

        if [ -L "$target" ] || [ -f "$target" ]; then
          cat "$target" > "$tmp_config"
        else
          touch "$tmp_config"
        fi

        rm -f "$target"
        install -m 600 "$tmp_config" "$target"

        FNOX_BIN="${config.programs.fnox.package}/bin/fnox"
        export FNOX_AGE_KEY_FILE="${config.programs.fnox.ageKeyFile}"
        export FNOX_CONFIG="$target"

        if [ ! -x "$FNOX_BIN" ]; then
          echo "Warning: fnox binary not found at $FNOX_BIN; skipping fnox secret seeding" >&2
          exit 0
        fi

        seed_secret() {
          name="$1"
          file="$2"

          if [ -z "$file" ] || [ ! -f "$file" ]; then
            return 2
          fi

          if "$FNOX_BIN" -c "$FNOX_CONFIG" get "$name" >/dev/null 2>&1; then
            return 0
          fi

          if [ ! -r "$file" ]; then
            echo "Warning: fnox seed source '$file' for '$name' is not readable; trying next source" >&2
            return 2
          fi

          value="$(cat "$file" 2>/dev/null || true)"
          if [ -z "$value" ]; then
            return 2
          fi

          set_output=""
          if ! set_output=$("$FNOX_BIN" -c "$FNOX_CONFIG" set "$name" "$value" 2>&1); then
            echo "Error: failed to seed fnox secret '$name' from '$file'" >&2
            echo "$set_output" >&2
            exit 1
          fi
        }

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: sources: ''
          for source in ${lib.concatMapStringsSep " " (source: "\"${source}\"") sources}; do
            if [ -f "$source" ]; then
              if seed_secret ${lib.escapeShellArg name} "$source"; then
                break
              else
                status=$?
                if [ "$status" -eq 1 ]; then
                  exit 1
                fi
              fi
            fi
          done
        '') seedSecretSources)}
      '';
    })
  ]);
}
