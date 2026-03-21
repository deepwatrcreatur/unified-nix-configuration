# Better Pattern for Podman Container Stacks

## Problem
The current `paperless-ngx.nix` has ~95 lines of boilerplate for:
- Secret management
- Directory creation
- Network setup
- Container definitions
- Systemd wiring
- Firewall rules

This will become unmaintainable with multiple stacks.

## Recommended Solution: Arion

**Arion** from Hercules CI is the established, production-ready solution for this exact use case.

- **Repository**: https://github.com/hercules-ci/arion
- **Stars**: 872+ (well-maintained, active community)
- **Purpose**: "Run docker-compose with help from Nix/NixOS"

### Why Arion?

1. **Docker Compose Compatibility**: Uses familiar docker-compose syntax
2. **Nix Integration**: Full access to nixpkgs, can build containers from Nix expressions
3. **Less Boilerplate**: Handles networking, dependencies, systemd integration automatically
4. **Type-Safe**: Nix-based configuration with proper option types
5. **Battle-Tested**: Used by many production NixOS deployments

### Example: Paperless-NGX with Arion

```nix
# arion-compose.nix
{ pkgs, ... }:
{
  project.name = "paperless";
  
  networks.paperless = {
    driver = "bridge";
  };

  services = {
    paperless-ngx = {
      image.name = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      service = {
        hostname = "paperless-ngx";
        ports = [ "8000:8000" ];
        volumes = [
          "/var/lib/paperless/data:/usr/src/paperless/data"
          "/var/lib/paperless/consume:/usr/src/paperless/consume"
        ];
        env_file = [ "/run/agenix/paperless-db-password" ];
        environment = {
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_DBNAME = "paperless_user";
          PAPERLESS_DBUSER = "paperless_user";
          PAPERLESS_URL = "https://paperless-ngx.local";
        };
        depends_on = [ "paperless-db" "paperless-redis" ];
        networks = [ "paperless" ];
      };
    };

    paperless-db = {
      image.name = "postgres:15";
      service = {
        hostname = "paperless-db";
        volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
        env_file = [ "/run/agenix/paperless-db-password" ];
        environment = {
          POSTGRES_DB = "paperless_user";
          POSTGRES_USER = "paperless_user";
        };
        networks = [ "paperless" ];
      };
    };

    paperless-redis = {
      image.name = "redis:latest";
      service = {
        hostname = "paperless-redis";
        networks = [ "paperless" ];
      };
    };
  };
}
```

Then in your NixOS configuration:

```nix
# hosts/nixos-lxc/podman/default.nix
{ inputs, ... }:
{
  imports = [
    inputs.arion.nixosModules.arion
    ./stacks/paperless-ngx.nix
  ];

  virtualisation.arion.projects.paperless.settings = {
    imports = [ ./stacks/paperless-compose.nix ];
  };
  
  # Secrets still managed by agenix
  age.secrets."paperless-db-password" = {
    file = ../../../secrets-agenix/paperless-db-password.age;
    mode = "0440";
  };

  # Directories
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless/consume 0777 root root -"
    "d /var/lib/paperless/data 0777 root root -"
    "d /var/lib/paperless/pgdata 0777 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 8000 ];
}
```

### Benefits Over Custom Module

1. **~95 lines → ~60 lines** (and more readable)
2. **No custom systemd wiring** - Arion handles it
3. **Standard docker-compose patterns** - Easy to understand
4. **Can convert existing docker-compose.yml** files directly
5. **Better documentation** - Established project with examples
6. **Future-proof** - Maintained by Hercules CI team

### Integration Steps

1. Add arion to flake inputs:
```nix
arion.url = "github:hercules-ci/arion";
arion.inputs.nixpkgs.follows = "nixpkgs";
```

2. Import the NixOS module in podman host
3. Convert existing paperless module to arion-compose format
4. Keep agenix secrets, tmpfiles, firewall rules in host config

## Alternative: Custom podman-stacks Module

If you prefer not to add another dependency, the custom module I started (modules/nixos/podman-stacks.nix) could work, but:

- **More maintenance burden**: You own the abstraction
- **Less features**: Missing things like health checks, restart policies, etc.
- **Reinventing the wheel**: Arion already solved this well

## Recommendation

**Use Arion.** It's the right tool for the job, battle-tested, and will save you time maintaining custom abstractions.

## References

- [Arion Documentation](https://docs.hercules-ci.com/arion/)
- [Arion Examples](https://github.com/hercules-ci/arion/tree/main/examples)
- [Arion NixOS Module Options](https://github.com/hercules-ci/arion/blob/main/src/nix/modules/composition/arion-base-image.nix)
