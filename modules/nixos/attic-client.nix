
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
    # 1. Define the system-level SOPS secret for the client token (if tokenFile is provided).
    sops.secrets."attic-client-token" = mkIf (cfg.tokenFile != null) {
      sopsFile = cfg.tokenFile;
      key = cfg.tokenKey;
      # This makes the decrypted secret available to the systemd service.
      path = "/run/secrets/attic-client-token";
      owner = config.users.users.root.name; # or a dedicated user
    };

    # 2. Create the attic.toml config file with a placeholder for the token.
    environment.etc."attic/config.toml" = {
      text = ''
        [servers.${cfg.cache}]
        endpoint = "${cfg.server}"
        token = "@ATTIC_CLIENT_TOKEN@"
      '';
      mode = "0644";
    };

    # 3. Create a systemd service to substitute the token into the config file.
    # This runs after sops-nix has decrypted the secrets during system activation.
    systemd.services.attic-client-config = {
      description = "Substitute Attic client token";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail
        if [[ -f "${config.sops.secrets."attic-client-token".path}" ]]; then
          echo "Configuring /etc/attic/config.toml with SOPS token..."
          token=$(cat "${config.sops.secrets."attic-client-token".path}")
          sed -i "s|@ATTIC_CLIENT_TOKEN@|$token|" /etc/attic/config.toml
        else
          echo "Warning: Attic client token not found. Attic pushes will likely fail."
        fi
      '';
    };

    # 4. Create the post-build hook script (fail-safe: never blocks builds)
    environment.etc."nix/attic-upload.sh" = {
      mode = "0755";
      text = ''
        #!${pkgs.bash}/bin/bash
        # DO NOT use 'set -e' - we want to continue even if push fails
        set -uo pipefail

        if [ -z "$OUT_PATHS" ]; then
          exit 0
        fi

        # Check if the token file exists
        if [ ! -f "${config.sops.secrets."attic-client-token".path}" ]; then
          echo "Attic: Token not available, skipping push" >&2
          exit 0
        fi

        # Wrap everything in a try-catch to never fail the build
        {
          echo "Attic: Attempting to push to cache '${cfg.cache}'..." >&2

          # Ensure the config service has run
          if ! systemctl is-active --quiet attic-client-config.service; then
            echo "Attic: Starting config service..." >&2
            systemctl start attic-client-config.service || {
              echo "Attic: Config service failed, skipping push" >&2
              exit 0
            }
          fi

          # Try to push, but don't fail if it errors
          if ${pkgs.attic-client}/bin/attic push ${cfg.cache} $OUT_PATHS 2>&1; then
            echo "Attic: Successfully pushed paths" >&2
          else
            echo "Attic: Push failed (server unavailable?), continuing anyway" >&2
          fi
        } || {
          echo "Attic: Upload hook failed, but build continues" >&2
        }

        # Always exit successfully so builds never fail
        exit 0
      '';
    };

    # 5. Configure Nix to use the post-build hook.
    nix.settings.post-build-hook = "/etc/nix/attic-upload.sh";

    # 6. Prepare the token for the Nix daemon.
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

    # 7. Make the Nix daemon wait for the token.
    systemd.services.nix-daemon.serviceConfig.Requires = "nix-attic-token.service";
    systemd.services.nix-daemon.after = [ "nix-attic-token.service" ];
  };
}
