{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.nix-user-config;
in
{
  options.services.nix-user-config = {
    enable = lib.mkEnableOption "User Nix configuration for Determinate Nix" // {
      default = true;
      description = "Whether to manage user Nix configuration (~/.config/nix/nix.conf)";
    };

    substituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "http://attic-cache:5001/cache-local"
        "https://cache.nixos.org"
      ];
      description = "List of binary cache substituters";
    };

    trustedPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # Attic cache key
        "cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw="
        # nix-serve cache key
        "cache.local:92faFQnuzuYUJ4ta3EYpqIaCMIZGenDoaPktsBucTe4="
        # Official cache key
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
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
      default = "attic-cache";
      description = "Machine name for netrc authentication (null to disable)";
    };

    netrcTokenPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/attic-client-token";
      description = "Path to the token file for netrc authentication";
    };

    githubTokenPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops-nix/secrets/github-token";
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
            extra-trusted-public-keys = ${lib.concatStringsSep " " cfg.trustedPublicKeys}
          '';
          force = true; # Overwrite existing backups to avoid clobbering errors
        };

        # Read GitHub token from file and append to nix.conf
        home.activation.nixConfigToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

      # Create netrc file in Determinate Nix's managed location (only if netrcMachine is set)
      (lib.mkIf (cfg.netrcMachine != null) {
        home.activation.nix-netrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                          netrc_file="/nix/var/determinate/netrc"

                          token=""
                          # Try fnox if available
                          if command -v fnox &> /dev/null && [ -f "$HOME/.config/sops/age/keys.txt" ]; then
                             export FNOX_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
                             token=$(fnox get ATTIC_CLIENT_JWT_TOKEN 2>/dev/null || echo "")
                          fi
                          
                          if [[ -z "$token" && -f "${cfg.netrcTokenPath}" ]]; then
                             token=$(cat "${cfg.netrcTokenPath}" 2>/dev/null || echo "")
                          fi

                          # Only create netrc if we have a token
                          if [[ -n "$token" ]]; then
                            # Append to Determinate Nix's netrc if not already present
                                      if [[ -w "$netrc_file" ]] || test -w "$(dirname "$netrc_file")" 2>/dev/null; then
                                        if ! grep -q "machine ${cfg.netrcMachine}" "$netrc_file" 2>/dev/null; then
                                          tee -a "$netrc_file" > /dev/null <<EOF
                machine ${cfg.netrcMachine}
                password $token
          EOF
                                echo "Added netrc authentication for ${cfg.netrcMachine} to Determinate Nix's netrc"
                              fi
                            else
                              echo "Warning: Cannot write to Determinate Nix's netrc at $netrc_file" >&2
                            fi
                          else
                            echo "Warning: No token found for netrc authentication (checked ${cfg.netrcTokenPath})" >&2
                          fi
        '';
      })
    ]
  );
}
