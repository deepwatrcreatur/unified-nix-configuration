# modules/nixos/attic-post-build-hook.nix
# IMPORTANT: Do NOT enable this on the host running atticd (cache-build-server)
# to avoid circular dependencies!
{ config, lib, pkgs, ... }:

let
  cfg = config.services.attic-post-build-hook;
  postBuildScript = pkgs.writeShellScript "attic-post-build-hook" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    echo "Post-build hook triggered with:" >&2
    echo "  DRV_PATH: $DRV_PATH" >&2
    echo "  OUT_PATHS: $OUT_PATHS" >&2

    # Check if this is a package we want to push (avoid pushing temporary builds)
    if [[ "$DRV_PATH" == *"-source.drv" ]] || [[ "$DRV_PATH" == *"tmp"* ]]; then
      echo "Skipping source/temporary derivation: $DRV_PATH" >&2
      exit 0
    fi

    # Push to attic using the configured cache
    for path in $OUT_PATHS; do
      echo "Pushing $path to attic cache: ${cfg.cacheName}" >&2
      if ${pkgs.attic-client}/bin/attic push ${cfg.cacheName} "$path" 2>&1; then
        echo "Successfully pushed $path" >&2
      else
        echo "Failed to push $path (non-fatal)" >&2
      fi
    done
  '';
in
{
  options.services.attic-post-build-hook = {
    enable = lib.mkEnableOption "Attic post-build hook for automatic cache uploads";

    cacheName = lib.mkOption {
      type = lib.types.str;
      default = "cache-build-server";
      description = "Name of the attic cache to push builds to";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "deepwatrcreatur";
      description = "User account that has attic-client configured";
    };
  };

  config = lib.mkIf cfg.enable {
    # Safety check: prevent enabling on cache-build-server
    assertions = [
      {
        assertion = config.networking.hostName != "cache-build-server";
        message = "attic-post-build-hook should NOT be enabled on cache-build-server to avoid circular dependencies!";
      }
    ];

    # Configure the post-build hook
    nix.settings.post-build-hook = toString postBuildScript;

    # Ensure the hook runs as the user with attic access
    nix.settings.allowed-users = [ cfg.user ];

    # Trust the user to modify the nix store (needed for post-build hooks)
    nix.settings.trusted-users = [ cfg.user ];

    # Ensure attic-client is available system-wide
    environment.systemPackages = [ pkgs.attic-client ];
  };
}