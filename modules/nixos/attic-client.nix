
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
  };

  config = mkIf cfg.enable {
    # 1. Define the system-level SOPS secret for the client token.
    sops.secrets."attic-client-token" = {
      sopsFile = ../../secrets/attic-client-token.yaml.enc;
      format = "binary";
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
    # This runs after sops-nix has decrypted the secrets.
    systemd.services.attic-client-config = {
      description = "Substitute Attic client token";
      wantedBy = [ "multi-user.target" ];
      after = [ "sops-nix.service" ];
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

    # 4. Create the post-build hook script.
    environment.etc."nix/attic-upload.sh" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        if [ -z "$OUT_PATHS" ]; then
          exit 0
        fi
        echo "Attic: Pushing paths to cache '${cfg.cache}'..."
        # Ensure the config service has run before trying to push
        systemctl is-active --quiet attic-client-config.service || \
          (echo "Waiting for attic-client-config service..." && systemctl start attic-client-config.service)
        ${pkgs.attic-client}/bin/attic push ${cfg.cache} $OUT_PATHS
      '';
    };

    # 5. Configure Nix to use the post-build hook.
    nix.settings.post-build-hook = "/etc/nix/attic-upload.sh";
  };
}
