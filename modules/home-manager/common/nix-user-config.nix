{
  config,
  lib,
  pkgs,
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
        "http://cache-build-server:5001/cache-local"
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
      default = "cache-build-server";
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Write user nix.conf with substituters and trusted keys
      xdg.configFile."nix/nix.conf".text = ''
        # User Nix configuration managed by home-manager
        experimental-features = ${lib.concatStringsSep " " cfg.experimentalFeatures}
        extra-substituters = ${lib.concatStringsSep " " cfg.substituters}
        extra-trusted-public-keys = ${lib.concatStringsSep " " cfg.trustedPublicKeys}
      '';
    }

    # Add GitHub token to nix.conf via activation script (runtime, not build-time)
    (lib.mkIf (cfg.githubTokenPath != null) {
      home.activation.github-nix-token = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        nix_conf_file="$HOME/.config/nix/nix.conf"
        token_file="${cfg.githubTokenPath}"

        if [[ -f "$token_file" ]]; then
          token=$(cat "$token_file" 2>/dev/null || echo "")
          if [[ -n "$token" ]]; then
            # Make file writable temporarily if needed
            if [[ -f "$nix_conf_file" ]]; then
              ${pkgs.coreutils}/bin/chmod u+w "$nix_conf_file"
            fi
            # Remove any existing github access-tokens line
            ${pkgs.gnused}/bin/sed -i '/^access-tokens.*github\.com/d' "$nix_conf_file"
            # Add the token
            echo "access-tokens = github.com:$token" >> "$nix_conf_file"
            echo "GitHub token added to nix.conf"
          fi
        fi
      '';
    })

    # Create netrc file in Determinate Nix's managed location (only if netrcMachine is set)
    (lib.mkIf (cfg.netrcMachine != null) {
      home.activation.nix-netrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                netrc_file="/nix/var/determinate/netrc"
                token_file="${cfg.netrcTokenPath}"

                # Only create netrc if we're the actual user and token exists
                if [[ "$HOME" == "${config.home.homeDirectory}" && -f "$token_file" ]]; then
                  token=$(cat "$token_file" 2>/dev/null || echo "")
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
                    echo "Warning: Token file empty at $token_file" >&2
                  fi
                fi
      '';
    })
  ]);
}
