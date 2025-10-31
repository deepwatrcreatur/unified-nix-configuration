{ config, lib, pkgs, ... }:

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
        "cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw="
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
  };

  config = lib.mkIf cfg.enable {
    # Create user Nix configuration (removed netrc-file setting for Determinate Nix compatibility)
    home.file.".config/nix/nix.conf".text = ''
      experimental-features = ${lib.concatStringsSep " " cfg.experimentalFeatures}
      substituters = ${lib.concatStringsSep " " cfg.substituters}
      trusted-public-keys = ${lib.concatStringsSep " " cfg.trustedPublicKeys}
    '';

    # Create netrc file in Determinate Nix's managed location
    home.activation.nix-netrc = lib.mkIf (cfg.netrcMachine != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
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
      ''
    );
  };
}
