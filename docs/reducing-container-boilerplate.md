# Reducing Container Boilerplate: The Right Way

## TL;DR

**Yes, reduce boilerplate!** But use **Nix functions and custom modules**, not Arion/Quadlet.

## Real-World Patterns from GitHub

### Pattern 1: Helper Functions (carpenike's approach)

Create a `lib/containers.nix` with reusable functions:

```nix
# lib/containers.nix
{ lib, pkgs }:
{
  # Standard container with common defaults
  mkContainer = name: cfg: {
    image = cfg.image;
    ports = cfg.ports or [];
    volumes = cfg.volumes or [];
    environment = cfg.environment or {};
    environmentFiles = cfg.environmentFiles or [];
    extraOptions = (cfg.extraOptions or []) ++ [
      "--pull=newer"
      "--restart=unless-stopped"
    ];
    dependsOn = cfg.dependsOn or [];
  };

  # Container with shared network + secrets
  mkNetworkedContainer = name: { network, secret ? null, ... }@cfg:
    (mkContainer name cfg) // {
      extraOptions = (cfg.extraOptions or []) ++ [
        "--network=${network}"
      ] ++ lib.optionals (secret != null) [
        "--env-file=${secret}"
      ];
    };
}
```

**Usage:**
```nix
# Use in your config
{ config, lib, pkgs, ... }:
let
  containerLib = import ../lib/containers.nix { inherit lib pkgs; };
in
{
  virtualisation.oci-containers.containers = {
    paperless-ngx = containerLib.mkNetworkedContainer "paperless-ngx" {
      network = "paperless";
      secret = config.age.secrets."paperless-db-password".path;
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      ports = [ "8000:8000" ];
      volumes = [
        "/var/lib/paperless/data:/usr/src/paperless/data"
        "/var/lib/paperless/consume:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_DBHOST = "paperless-db";
      };
      dependsOn = [ "paperless-db" "paperless-redis" ];
    };
    
    # Much simpler!
    paperless-db = containerLib.mkNetworkedContainer "paperless-db" {
      network = "paperless";
      secret = config.age.secrets."paperless-db-password".path;
      image = "postgres:15";
      volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
    };
  };
}
```

### Pattern 2: Custom NixOS Module (nixflix's approach)

Create reusable modules for common stacks:

```nix
# modules/container-stack.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.containerStacks;
  
  # Helper to create network service
  mkNetwork = name: {
    "podman-network-${name}" = {
      description = "Podman network ${name}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network exists ${name} || ${pkgs.podman}/bin/podman network create ${name}";
      };
    };
  };
in
{
  options.services.containerStacks = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        network = mkOption {
          type = types.str;
          description = "Network name for this stack";
        };
        
        secrets = mkOption {
          type = types.attrsOf types.path;
          default = {};
          description = "Secrets to mount in containers";
        };
        
        containers = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              image = mkOption { type = types.str; };
              ports = mkOption { type = types.listOf types.str; default = []; };
              volumes = mkOption { type = types.listOf types.str; default = []; };
              environment = mkOption { type = types.attrsOf types.str; default = {}; };
              dependsOn = mkOption { type = types.listOf types.str; default = []; };
            };
          });
        };
        
        directories = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Directories to create";
        };
        
        firewallPorts = mkOption {
          type = types.listOf types.port;
          default = [];
        };
      };
    });
    default = {};
  };
  
  config = mkIf (cfg != {}) {
    # Create networks
    systemd.services = mkMerge (
      mapAttrsToList (stackName: stackCfg: mkNetwork stackCfg.network) cfg
    );
    
    # Deploy containers
    virtualisation.oci-containers.containers = mkMerge (
      mapAttrsToList (stackName: stackCfg:
        mapAttrs (containerName: containerCfg: {
          inherit (containerCfg) image ports volumes environment dependsOn;
          environmentFiles = attrValues stackCfg.secrets;
          extraOptions = [ "--network=${stackCfg.network}" ];
        }) stackCfg.containers
      ) cfg
    );
    
    # Create directories
    systemd.tmpfiles.rules = flatten (
      mapAttrsToList (stackName: stackCfg:
        map (dir: "d ${dir} 0777 root root -") stackCfg.directories
      ) cfg
    );
    
    # Firewall
    networking.firewall.allowedTCPPorts = flatten (
      mapAttrsToList (stackName: stackCfg: stackCfg.firewallPorts) cfg
    );
  };
}
```

**Usage:**
```nix
# Much cleaner!
services.containerStacks.paperless = {
  network = "paperless";
  
  secrets."db-password" = config.age.secrets."paperless-db-password".path;
  
  containers = {
    paperless-ngx = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      ports = [ "8000:8000" ];
      volumes = [
        "/var/lib/paperless/data:/usr/src/paperless/data"
        "/var/lib/paperless/consume:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_DBHOST = "paperless-db";
      };
      dependsOn = [ "paperless-db" "paperless-redis" ];
    };
    
    paperless-db = {
      image = "postgres:15";
      volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
    };
    
    paperless-redis = {
      image = "redis:latest";
    };
  };
  
  directories = [
    "/var/lib/paperless/consume"
    "/var/lib/paperless/data"
    "/var/lib/paperless/pgdata"
  ];
  
  firewallPorts = [ 8000 ];
};
```

### Pattern 3: Template Function (simplest)

Just extract common parts to a function:

```nix
# In your paperless module
{ config, lib, pkgs, ... }:

let
  # Common settings for all paperless containers
  paperlessContainer = name: extras: {
    image = extras.image;
    extraOptions = [ "--network=paperless" ] ++ (extras.extraOptions or []);
    environmentFiles = [ config.age.secrets."paperless-db-password".path ];
  } // (removeAttrs extras [ "image" "extraOptions" ]);
in
{
  virtualisation.oci-containers.containers = {
    paperless-ngx = paperlessContainer "paperless-ngx" {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      ports = [ "8000:8000" ];
      volumes = [ /* ... */ ];
      environment = { /* ... */ };
      dependsOn = [ "paperless-db" "paperless-redis" ];
    };
    
    paperless-db = paperlessContainer "paperless-db" {
      image = "postgres:15";
      volumes = [ "/var/lib/paperless/pgdata:/var/lib/postgresql/data" ];
    };
    
    paperless-redis = paperlessContainer "paperless-redis" {
      image = "redis:latest";
    };
  };
}
```

## Comparison

### Before (Your Current Setup)
```nix
# 95 lines of repetitive config
virtualisation.oci-containers.containers.paperless-ngx = {
  image = "...";
  extraOptions = [ "--network=paperless" ];
  environmentFiles = [ config.age.secrets... ];
  # ... repeated for each container
};
```

### After Pattern 1 (Helper Functions)
```nix
# 60 lines, reusable across hosts
paperless-ngx = containerLib.mkNetworkedContainer "paperless-ngx" {
  # Only the unique parts!
};
```

### After Pattern 2 (Custom Module)
```nix
# 45 lines, declarative
services.containerStacks.paperless = {
  containers = { /* just the containers */ };
  # Network, secrets, firewall handled automatically
};
```

### After Pattern 3 (Template Function)
```nix
# 55 lines, quick and simple
paperless-ngx = paperlessContainer "paperless-ngx" {
  # Shared settings applied automatically
};
```

## Recommendation for Your Repo

**Start with Pattern 3** (template function) because:
1. ✅ Simplest to implement (5 minutes)
2. ✅ Works immediately
3. ✅ Easy to understand
4. ✅ Can evolve to Pattern 1 or 2 later

Then if you add more stacks, upgrade to **Pattern 2** (custom module).

## Implementation

I'll create:
1. `lib/container-helpers.nix` - Helper functions
2. `modules/nixos/container-stack.nix` - Custom module  
3. Updated `paperless-ngx.nix` using the helpers

Want me to implement this?

## Why This is Better Than Arion/Quadlet

| Feature | Arion/Quadlet | Nix Functions/Modules |
|---------|---------------|----------------------|
| **Boilerplate reduction** | ✅ Yes | ✅ Yes |
| **Type safety** | ❌ No (text) | ✅ Yes (NixOS options) |
| **Nix expression power** | ⚠️ Limited | ✅ Full |
| **Works reliably** | ❌ Port issues | ✅ Yes |
| **Dependencies** | ⚠️ External | ✅ Built-in Nix |
| **Reusable** | ⚠️ Across hosts | ✅ Across everything |
| **Maintainable** | ⚠️ Two systems | ✅ One system |

## Real Repos Using This Pattern

- **nixflix** (289⭐): Media server with custom modules
- **carpenike/nix-config**: Enterprise-grade helper functions
- **Your repo**: Should adopt this approach!

The pattern is proven, maintainable, and actually works.
