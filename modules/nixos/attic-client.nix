# modules/nixos/attic-client.nix
# This module configures the local Nix daemon to use an Attic cache.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.myModules.attic-client;

in
{
  options.myModules.attic-client = {
    enable = mkEnableOption "Attic client for NixOS";

    server = mkOption {
      type = types.str;
      default = "http://cache-build-server:5001";
      description = "The URL of the Attic cache server.";
    };

    cache = mkOption {
      type = types.str;
      default = "cache-local";
      description = "The name of the cache to push to.";
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the SOPS encrypted token file. If null, secret must be configured manually.";
    };

    tokenKey = mkOption {
      type = types.str;
      default = "ATTIC_CLIENT_JWT_TOKEN";
      description = "The key name in the SOPS file containing the token.";
    };
  };

  config = mkIf cfg.enable {
    # 1. Define the system-level SOPS secret for the client token.
    sops.secrets."attic-client-token" = mkIf (cfg.tokenFile != null) {
      sopsFile = cfg.tokenFile;
      key = cfg.tokenKey;
      path = "/run/secrets/attic-client-token";
      owner = config.users.users.root.name;
    };

    # 2. Create the post-build hook script (fail-safe: never blocks builds)
    environment.etc."nix/attic-upload.sh" = {
      mode = "0755";
      text = ''
        #!${pkgs.bash}/bin/bash
        # DO NOT use 'set -e' - we want to continue even if push fails
        set -uo pipefail

        if [ -z "$OUT_PATHS" ]; then
          exit 0
        fi

        token_file="${config.sops.secrets."attic-client-token".path}"

        if [ ! -f "$token_file" ]; then
          echo "Attic: Token not available, skipping push" >&2
          exit 0
        fi

        token=$(cat "$token_file")

        # Create a temporary config for attic.
        # `attic` does not support a `--config` flag; it reads from XDG_CONFIG_HOME.
        temp_dir=$(mktemp -d)

        # Ensure cleanup happens on exit
        trap 'rm -rf "$temp_dir"' EXIT

        mkdir -p "$temp_dir/attic"
        cat > "$temp_dir/attic/config.toml" <<EOF
        [servers.cache-build-server]
        endpoint = "${cfg.server}"
        token = "$token"
        EOF

        export XDG_CONFIG_HOME="$temp_dir"

        # Wrap everything in a try-catch to never fail the build
        {
          echo "Attic: Attempting to push to cache '${cfg.cache}'..." >&2
          echo "Attic: Server endpoint: ${cfg.server}" >&2
          echo "Attic: Cache name: ${cfg.cache}" >&2
          echo "Attic: Token file exists: $(test -f "$token_file" && echo 'yes' || echo 'no')" >&2
          echo "Attic: Token length: $(echo -n "$token" | wc -c) characters" >&2

          if ${pkgs.attic-client}/bin/attic push cache-build-server:${cfg.cache} $OUT_PATHS; then
            echo "Attic: Successfully pushed paths" >&2
          else
            echo "Attic: Push failed - checking server connectivity..." >&2
            # Test server connectivity
            if ${pkgs.curl}/bin/curl -s -f --max-time 10 "${cfg.server}/_attic/v1/cache/${cfg.cache}/info" -H "Authorization: Bearer $token" >/dev/null 2>&1; then
              echo "Attic: Server reachable, likely permission issue" >&2
            else
              echo "Attic: Server unreachable or auth failed - check network/server status" >&2
            fi
            echo "Attic: Continuing build despite push failure" >&2
          fi
        } || {
          echo "Attic: Upload hook failed unexpectedly, but build continues" >&2
        }

        # Always exit successfully so builds never fail
        exit 0
      '';
    };

    # 3. Configure Nix to use the post-build hook.
    # Use mkDefault so other modules can override (e.g. `nix-attic-infra`).
    nix.settings.post-build-hook = mkDefault "/etc/nix/attic-upload.sh";

    # 4. Prepare the token for the Nix daemon for pulling from the cache.
    systemd.services.nix-attic-token = {
      description = "Prepare Attic token for Nix daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        if [[ -f "${config.sops.secrets."attic-client-token".path}" ]]; then
          echo "Preparing Attic token for Nix daemon..."
          mkdir -p /run/nix
          token=$(cat "${config.sops.secrets."attic-client-token".path}")
          echo "bearer $token" > /run/nix/attic-token-bearer
          chmod 0644 /run/nix/attic-token-bearer
        else
          echo "Warning: Attic client token not found. Nix pulls will likely fail."
        fi
      '';
    };

    # 5. Make the Nix daemon wait for the token.
    systemd.services.nix-daemon.serviceConfig.Requires = "nix-attic-token.service";
    systemd.services.nix-daemon.after = [ "nix-attic-token.service" ];
  };
}
