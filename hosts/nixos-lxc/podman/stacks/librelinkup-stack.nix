# hosts/nixos-lxc/podman/stacks/librelinkup-stack.nix
# LibreLinkUp to Nightscout bridge
{ config, lib, pkgs, ... }:

let
  optSec = import ../../../../modules/helpers/optional-secrets.nix { inherit lib; };

  librelinkupSecret = optSec.mkSecret "librelinkup-env" {
    file = ../../../../secrets-agenix/librelinkup-env.age;
  };
in

{
  # Agenix secret containing LibreLinkUp credentials
  # Format: KEY=value (one per line, will be loaded as environment file)
  age.secrets."librelinkup-env" = librelinkupSecret.definition // {
    owner = "root";
    group = "root";
    mode = "0440";
  };

  services.containerStacks.librelinkup = {
    network = "nightscout";  # Same network as nightscout for easy communication

    # Reference secrets (mounted as env file in container)
    secrets = lib.optionalAttrs librelinkupSecret.exists {
      "librelinkup-env".path = config.age.secrets."librelinkup-env".path;
    };

    containers = {
      librelinkup-bridge = {
        image = "timoschlueter/nightscout-librelink-up:latest";
        dependsOn = [ "nightscout" ];
        environment = {
          # Non-sensitive config
          LINK_UP_REGION = "CA";
          LINK_UP_TIME_INTERVAL = "5";
          NIGHTSCOUT_URL = "nightscout.deepwatercreature.com";
          NIGHTSCOUT_DEVICE_NAME = "librelinkup-bridge";
          LOG_LEVEL = "info";
          RETRY_ATTEMPTS = "2";
          RETRY_INTERVAL_SECONDS = "30";
        };
        # Sensitive vars (LINK_UP_USERNAME, LINK_UP_PASSWORD, NIGHTSCOUT_API_TOKEN)
        # are loaded from the agenix secret env file
      };
    };
  };
}
