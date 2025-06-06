# modules/nightscout.nix
{ config, pkgs, lib, ... }:

{
  # 1. Define the secrets file using sops-nix
  sops.secrets."MONGO_USER" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0444"; # Ensure readable by Podman
  };
  sops.secrets."MONGO_PASSWORD" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0444";
  };
  sops.secrets."API_SECRET" = {
    sopsFile = ./../secrets/nightscout-secrets.yaml;
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0444";
  };

  # 2. Define the containers
  virtualisation.oci-containers = {
    backend = "podman"; # Explicitly set Podman as the backend
    containers = {
      # The MongoDB database container
      mongo = {
        image = "mongo:4.4";
        autoStart = true;
        volumes = [ "mongo-data:/data/db" ];
        environment = {
          MONGO_INITDB_ROOT_USERNAME = "$(MONGO_USER)";
          MONGO_INITDB_ROOT_PASSWORD = "$(MONGO_PASSWORD)";
        };
        extraOptions = [ "--network=nightscout-network" "--log-driver=journald" ];
      };

      # The Nightscout application container
      nightscout = {
        image = "nightscout/cgm-remote-monitor:latest";
        autoStart = true;
        ports = [ "1337:1337" ];
        environment = {
          MONGO_CONNECTION = "mongodb://$(MONGO_USER):$(MONGO_PASSWORD)@mongo:27017/nightscout?authSource=admin";
          API_SECRET = "$(API_SECRET)";
          INSECURE_USE_HTTP = "true";
          DISPLAY_UNITS = "mmol/L";
        };
        extraOptions = [ "--network=nightscout-network" "--log-driver=journald" ];
      };
    };
  };

  # 3. Create a Podman network for the containers
  systemd.services.podman-network-nightscout-network = {
    description = "Podman network for Nightscout and MongoDB";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create nightscout-network";
      ExecStop = "${pkgs.podman}/bin/podman network rm nightscout-network";
    };
  };

  # 4. Systemd service overrides for Podman containers
  systemd.services."podman-mongo" = {
    wants = [ "sops-nix.service" "podman-network-nightscout-network.service" ];
    after = [ "sops-nix.service" "podman-network-nightscout-network.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/secrets/nightscout_env";
      User = "root"; # Ensure access to secret files
    };
  };

  systemd.services."podman-nightscout" = {
    wants = [ "sops-nix.service" "podman-mongo.service" "podman-network-nightscout-network.service" ];
    after = [ "sops-nix.service" "podman-mongo.service" "podman-network-nightscout-network.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/secrets/nightscout_env";
      User = "root";
    };
  };

  # 5. Create an environment file for secrets
  environment.etc."secrets/nightscout_env".text = ''
    MONGO_USER=$(cat ${config.sops.secrets."MONGO_USER".path})
    MONGO_PASSWORD=$(cat ${config.sops.secrets."MONGO_PASSWORD".path})
    API_SECRET=$(cat ${config.sops.secrets."API_SECRET".path})
  '';

  # 6. Open the firewall port for Nightscout
  networking.firewall.allowedTCPPorts = [ 1337 ];
}
