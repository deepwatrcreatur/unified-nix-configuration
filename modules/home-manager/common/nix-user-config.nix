{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.nix-user-config;
  cacheTrust = import ../../../lib/cache-trust.nix;
  atticCache = import ../../../lib/attic-cache.nix;
  legacyNetrcEntries =
    lib.optional (cfg.netrcMachine != null) {
      machine = cfg.netrcMachine;
      login = null;
      passwordPath = cfg.netrcTokenPath;
      fnoxSecretName = "ATTIC_CLIENT_JWT_TOKEN";
    };

  netrcEntries = legacyNetrcEntries ++ cfg.netrcEntries;
in
{
  options.services.nix-user-config = {
    enable = lib.mkEnableOption "User Nix configuration for Determinate Nix" // {
      default = true;
      description = "Whether to manage user Nix configuration (~/.config/nix/nix.conf)";
    };

    substituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = atticCache.defaultSubstituters { includeNixCi = false; };
      description = "List of binary cache substituters";
    };

    trustedPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = atticCache.defaultTrustedPublicKeys { includeNixCi = false; };
      description = "List of trusted public keys for substituters";
    };

    experimentalFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "nix-command"
        "flakes"
        "impure-derivations"
        "ca-derivations"
      ];
      description = "Experimental features to enable";
    };

    netrcMachine = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = atticCache.serverName;
      description = "Machine name for netrc authentication (null to disable)";
    };

    netrcTokenPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/attic-client-token";
      description = "Path to the token file for netrc authentication";
    };

    netrcEntries = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            machine = lib.mkOption {
              type = lib.types.str;
              description = "Machine name for the netrc stanza.";
            };

            login = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional login value for the netrc stanza.";
            };

            passwordPath = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Path to a file containing the password/token.";
            };

            fnoxSecretName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional fnox secret name used before passwordPath.";
            };
          };
        }
      );
      default = [ ];
      description = "Managed netrc entries written to /nix/var/determinate/netrc.";
    };

    netrcSnippetPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths to preformatted netrc snippets to append to the managed Determinate Nix netrc.";
    };

    githubTokenPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.home.homeDirectory}/.config/git/github-token";
      description = "Path to GitHub token file for API authentication (null to disable)";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Write user nix.conf with substituters, trusted keys, and GitHub token
        home.file.".config/nix/nix.conf" = {
          text = ''
            # User Nix configuration managed by home-manager
            experimental-features = ${lib.concatStringsSep " " cfg.experimentalFeatures}
            extra-substituters = ${lib.concatStringsSep " " cfg.substituters}
            extra-trusted-substituters = ${lib.concatStringsSep " " cfg.substituters}
            extra-trusted-public-keys = ${lib.concatStringsSep " " cfg.trustedPublicKeys}
          '';
          force = true; # Overwrite existing backups to avoid clobbering errors
        };

        # Read GitHub token from file and append to nix.conf when configured
        home.activation.nixConfigToken = lib.mkIf (cfg.githubTokenPath != null) (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          nix_conf="$HOME/.config/nix/nix.conf"
          token_path="${cfg.githubTokenPath}"

          token=""
          # Try fnox if available
          if command -v fnox &> /dev/null && [ -f "$HOME/.config/sops/age/keys.txt" ]; then
            export FNOX_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
            token=$(fnox get GITHUB_TOKEN 2>/dev/null || echo "")
          fi

          if [[ -z "$token" && -f "$token_path" ]]; then
            token=$(cat "$token_path")
          fi

          if [[ -n "$token" ]]; then
              # Remove any existing access-tokens line and append new one
              grep -v "^access-tokens = github.com=" "$nix_conf" > "$nix_conf.tmp" 2>/dev/null || cp "$nix_conf" "$nix_conf.tmp"
              echo "access-tokens = github.com=$token" >> "$nix_conf.tmp"
              mv "$nix_conf.tmp" "$nix_conf"
              echo "Configured GitHub access token in $nix_conf"
            fi
        '';
      }

      # Create or refresh Determinate Nix's managed netrc file.
      (lib.mkIf (netrcEntries != [ ] || cfg.netrcSnippetPaths != [ ]) {
        home.activation.nix-netrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          netrc_file="/nix/var/determinate/netrc"
          managed_begin="# BEGIN home-manager managed nix-user-config"
          managed_end="# END home-manager managed nix-user-config"
          tmp_existing="$(mktemp)"
          tmp_managed="$(mktemp)"

          mkdir -p "$(dirname "$netrc_file")"
          touch "$netrc_file"
          chmod 600 "$netrc_file"

          ${pkgs.gawk}/bin/awk -v begin="$managed_begin" -v end="$managed_end" '
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            !skip { print }
          ' "$netrc_file" > "$tmp_existing"

          {
            echo "$managed_begin"
            ${lib.concatMapStringsSep "\n" (entry: ''
              password=""
              ${lib.optionalString (entry.fnoxSecretName != null) ''
                if command -v fnox &> /dev/null && [ -f "$HOME/.config/sops/age/keys.txt" ]; then
                  export FNOX_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
                  password=$(fnox get ${lib.escapeShellArg entry.fnoxSecretName} 2>/dev/null || echo "")
                fi
              ''}
              ${lib.optionalString (entry.passwordPath != null) ''
                if [[ -z "$password" && -f ${lib.escapeShellArg entry.passwordPath} ]]; then
                  password=$(cat ${lib.escapeShellArg entry.passwordPath} 2>/dev/null || echo "")
                fi
              ''}

              if [[ -n "$password" ]]; then
                echo "machine ${entry.machine}"
                ${lib.optionalString (entry.login != null) ''
                  echo "login ${entry.login}"
                ''}
                echo "password $password"
                echo
              else
                echo "Warning: No token found for ${entry.machine} netrc entry" >&2
              fi
            '') netrcEntries}

            ${lib.concatMapStringsSep "\n" (snippetPath: ''
              if [[ -f ${lib.escapeShellArg snippetPath} ]]; then
                cat ${lib.escapeShellArg snippetPath}
                echo
              else
                echo "Warning: netrc snippet ${snippetPath} not found" >&2
              fi
            '') cfg.netrcSnippetPaths}
            echo "$managed_end"
          } > "$tmp_managed"

          cat "$tmp_existing" > "$netrc_file"
          if [[ -s "$netrc_file" ]]; then
            printf '\n' >> "$netrc_file"
          fi
          cat "$tmp_managed" >> "$netrc_file"
          chmod 600 "$netrc_file"

          rm -f "$tmp_existing" "$tmp_managed"
        '';
      })
    ]
  );
}
