{ config, lib, pkgs, ... }:
{
  # Attic client configuration for all machines (except the cache server itself)

  config = lib.mkIf (config.networking.hostName != "cache-build-server") {
    # Add attic-client to system packages
    environment.systemPackages = with pkgs; [
      attic-client
    ];

    # Client-side post-build hook to push to Attic cache
    nix.settings.post-build-hook = "/etc/nix/attic-upload.sh";

    environment.etc."nix/attic-upload.sh" = {
      text = ''
        #!/bin/sh
        set -eu
        set -f # disable globbing
        export IFS=' '

        echo "Uploading to Attic cache:" $OUT_PATHS

        # Set server for attic client
        export ATTIC_SERVER="http://cache.deepwatercreature.com:5001"

        # Push to Attic cache server
        ${pkgs.attic-client}/bin/attic push cache-local $OUT_PATHS || {
          echo "Warning: Failed to upload to Attic cache"
          exit 0  # Don't fail the build if cache upload fails
        }

        echo "Successfully uploaded to Attic cache"
      '';
      mode = "0755";
    };

    # Attic client configuration
    environment.etc."attic/config.toml" = {
      text = ''
        # Default Attic client configuration
        [cache.cache-local]
        endpoint = "http://cache.deepwatercreature.com:5001/"

        # Optional: Add authentication token here if needed in the future
        # token = "attic_..."
      '';
    };
  };
}