# modules/nixos/container-stack.nix
# NixOS module for declarative multi-container stacks
# Makes it easy to convert docker-compose files to NixOS config

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.containerStacks;

  # Helper to create network service
  mkNetworkService = name: {
    "podman-network-${name}" = {
      description = "Podman network: ${name}";
      after = [ "network.target" ];
      before = [ "podman.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network exists ${name} || ${pkgs.podman}/bin/podman network create ${name}";
        ExecStop = "${pkgs.podman}/bin/podman network rm -f ${name}";
      };
    };
  };

  # Convert our stack config to oci-containers format
  stackToContainers = stackName: stackCfg:
    mapAttrs (containerName: containerCfg: {
      inherit (containerCfg) image;
      ports = containerCfg.ports or [];
      volumes = containerCfg.volumes or [];
      environment = containerCfg.environment or {};
      environmentFiles = (containerCfg.environmentFiles or []) ++ 
        (map (secret: secret.path) (attrValues stackCfg.secrets));
      extraOptions = (containerCfg.extraOptions or []) ++ [
        "--network=${stackCfg.network}"
        "--pull=newer"
      ];
      dependsOn = containerCfg.dependsOn or [];
      autoStart = containerCfg.autoStart or true;
      user = containerCfg.user or null;
      workdir = containerCfg.workdir or null;
      cmd = containerCfg.cmd or [];
      entrypoint = containerCfg.entrypoint or null;
      hostname = containerCfg.hostname or containerName;
      labels = containerCfg.labels or {};
      log-driver = containerCfg.log-driver or "journald";
    }) stackCfg.containers;

in
{
  options.services.containerStacks = mkOption {
    type = types.attrsOf (types.submodule ({ name, ... }: {
      options = {
        enable = mkEnableOption "this container stack" // { default = true; };

        network = mkOption {
          type = types.str;
          default = name;
          description = "Network name for this stack (defaults to stack name)";
          example = "myapp-network";
        };

        containers = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              image = mkOption {
                type = types.str;
                description = "Container image (with optional tag)";
                example = "postgres:15";
              };

              ports = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Port mappings (host:container)";
                example = [ "8080:80" "8443:443" ];
              };

              volumes = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Volume mappings (host:container)";
                example = [ "/var/lib/data:/data" ];
              };

              environment = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "Environment variables";
                example = { POSTGRES_DB = "mydb"; };
              };

              environmentFiles = mkOption {
                type = types.listOf types.path;
                default = [];
                description = "Environment files (for additional secrets)";
              };

              extraOptions = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Extra podman options";
                example = [ "--cap-add=NET_ADMIN" ];
              };

              dependsOn = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Container dependencies (will start after these)";
                example = [ "postgres" "redis" ];
              };

              autoStart = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to start container automatically";
              };

              user = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "User to run container as";
                example = "1000:1000";
              };

              workdir = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Working directory in container";
              };

              cmd = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Command to run (overrides CMD)";
              };

              entrypoint = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Entrypoint override";
              };

              hostname = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Container hostname (defaults to container name)";
              };

              labels = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "Container labels";
              };

              log-driver = mkOption {
                type = types.str;
                default = "journald";
                description = "Logging driver";
              };
            };
          });
          description = "Containers in this stack";
          example = literalExpression ''
            {
              web = {
                image = "nginx:latest";
                ports = [ "80:80" ];
              };
              db = {
                image = "postgres:15";
                volumes = [ "/var/lib/postgres:/var/lib/postgresql/data" ];
              };
            }
          '';
        };

        secrets = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              path = mkOption {
                type = types.path;
                description = "Path to secret file (e.g., agenix secret path)";
              };
            };
          });
          default = {};
          description = "Secrets to mount in ALL containers in this stack";
          example = literalExpression ''
            {
              db-password = {
                path = config.age.secrets."myapp-db-password".path;
              };
            }
          '';
        };

        directories = mkOption {
          type = types.listOf (types.submodule {
            options = {
              path = mkOption {
                type = types.str;
                description = "Directory path to create";
              };
              mode = mkOption {
                type = types.str;
                default = "0755";
                description = "Directory permissions";
              };
              user = mkOption {
                type = types.str;
                default = "root";
                description = "Directory owner";
              };
              group = mkOption {
                type = types.str;
                default = "root";
                description = "Directory group";
              };
            };
          });
          default = [];
          description = "Directories to create for this stack";
          example = literalExpression ''
            [
              { path = "/var/lib/myapp/data"; mode = "0777"; }
              { path = "/var/lib/myapp/logs"; mode = "0755"; }
            ]
          '';
        };

        firewall = mkOption {
          type = types.submodule {
            options = {
              allowedTCPPorts = mkOption {
                type = types.listOf types.port;
                default = [];
                description = "TCP ports to open in firewall";
              };
              allowedUDPPorts = mkOption {
                type = types.listOf types.port;
                default = [];
                description = "UDP ports to open in firewall";
              };
            };
          };
          default = {};
          description = "Firewall configuration for this stack";
        };
      };
    }));
    default = {};
    description = "Declarative container stacks (docker-compose style)";
    example = literalExpression ''
      {
        paperless = {
          network = "paperless";
          containers = {
            paperless-ngx = {
              image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
              ports = [ "8000:8000" ];
              environment = {
                PAPERLESS_REDIS = "redis://paperless-redis:6379";
                PAPERLESS_DBHOST = "paperless-db";
              };
            };
            paperless-db = {
              image = "postgres:15";
              volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
            };
          };
          secrets."db-password".path = config.age.secrets."paperless-db-password".path;
          directories = [
            { path = "/var/lib/paperless/data"; mode = "0777"; }
          ];
          firewall.allowedTCPPorts = [ 8000 ];
        };
      }
    '';
  };

  config = mkIf (cfg != {}) (mkMerge [
    # Create networks
    {
      systemd.services = mkMerge (
        mapAttrsToList (stackName: stackCfg:
          mkIf stackCfg.enable (mkNetworkService stackCfg.network)
        ) cfg
      );
    }

    # Deploy containers
    {
      virtualisation.oci-containers.containers = mkMerge (
        mapAttrsToList (stackName: stackCfg:
          mkIf stackCfg.enable (stackToContainers stackName stackCfg)
        ) cfg
      );
    }

    # Create directories
    {
      systemd.tmpfiles.rules = flatten (
        mapAttrsToList (_stackName: stackCfg:
          if stackCfg.enable then
            map (dir: "d ${dir.path} ${dir.mode} ${dir.user} ${dir.group} -") stackCfg.directories
          else
            [ ]
        ) cfg
      );
    }

    # Configure firewall
    {
      networking.firewall = {
        allowedTCPPorts = flatten (
          mapAttrsToList (_stackName: stackCfg:
            if stackCfg.enable then stackCfg.firewall.allowedTCPPorts else [ ]
          ) cfg
        );
        allowedUDPPorts = flatten (
          mapAttrsToList (_stackName: stackCfg:
            if stackCfg.enable then stackCfg.firewall.allowedUDPPorts else [ ]
          ) cfg
        );
      };
    }
  ]);
}
