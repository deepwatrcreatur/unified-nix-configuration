# hosts/nixos-lxc/podman/stacks/nightscout-stack.nix
# Nightscout CGM remote monitoring using container-stack module
{ config, lib, pkgs, ... }:

let
  optSec = import ../../../../modules/helpers/optional-secrets.nix { inherit lib; };

  nightscoutSecret = optSec.mkSecret "nightscout-api-secret" {
    file = ../../../../secrets-agenix/nightscout-api-secret.age;
  };
in

{
  # Agenix secret for API_SECRET (12+ character string for API authentication)
  age.secrets."nightscout-api-secret" = nightscoutSecret.definition // {
    owner = "root";
    group = "root";
    mode = "0440";
  };

  services.containerStacks.nightscout = {
    network = "nightscout";

    # Reference secrets (mounted in ALL containers as env files)
    secrets = lib.optionalAttrs nightscoutSecret.exists {
      "api-secret".path = config.age.secrets."nightscout-api-secret".path;
    };

    containers = {
      nightscout = {
        image = "nightscout/cgm-remote-monitor:latest";
        dependsOn = [ "nightscout-mongo" ];
        environment = {
          # MongoDB connection
          MONGO_CONNECTION = "mongodb://nightscout-mongo:27017/nightscout";

          # Node environment
          NODE_ENV = "production";

          # Server settings
          HOSTNAME = "0.0.0.0";
          PORT = "1337";

          # Display settings
          DISPLAY_UNITS = "mg/dl";  # or mmol/L
          TIME_FORMAT = "12";       # 12 or 24

          # Features/Plugins - common ones enabled
          ENABLE = "careportal basal iob cob bwp cage sage iage bage pump openaps loop override";

          # Base URL for callbacks
          BASE_URL = "https://nightscout.deepwatercreature.com";

          # Auth settings - default role for viewers
          AUTH_DEFAULT_ROLES = "readable";
        };
      };

      nightscout-mongo = {
        image = "mongo:4.4";
        volumes = [
          "/var/lib/nightscout/mongo:/data/db"
        ];
      };
    };

    # Persistent directories
    directories = [
      { path = "/var/lib/nightscout/mongo"; mode = "0755"; }
    ];

    # Firewall - expose the proxy port
    firewall.allowedTCPPorts = [ 11337 ];
  };

  # Host-side proxy to forward traffic into the container network
  systemd.services.nightscout-host-proxy = {
    description = "Host-side Nightscout proxy";
    after = [ "network-online.target" "podman-nightscout.service" ];
    wants = [ "network-online.target" "podman-nightscout.service" ];
    wantedBy = [ "multi-user.target" ];
    partOf = [ "podman-nightscout.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = let
        podman = "${pkgs.podman}/bin/podman";
        socat = "${pkgs.socat}/bin/socat";
        shell = "${pkgs.runtimeShell}";
      in
        "${shell} -c 'target_ip=$(${podman} inspect nightscout --format \"{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\"); exec ${socat} TCP-LISTEN:11337,reuseaddr,fork,bind=0.0.0.0 TCP:$${target_ip}:1337'";
    };
  };
}
