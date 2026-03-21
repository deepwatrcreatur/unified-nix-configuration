# Guide for Agents: Converting Docker-Compose to Container Stack

## For AI Coding Agents

When converting a `docker-compose.yml` file to NixOS container-stack format, follow this mapping:

### Direct Mappings

```yaml
# docker-compose.yml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./data:/data
      - ./config:/etc/nginx
    environment:
      KEY: value
      ANOTHER: value
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped
    networks:
      - mynetwork

  db:
    image: postgres:15
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: mydb

networks:
  mynetwork:

volumes:
  db-data:
```

**Converts to:**

```nix
# paperless-stack.nix (or whatever-stack.nix)
{ config, ... }:

{
  services.containerStacks.myapp = {
    network = "mynetwork";  # From docker-compose networks

    containers = {
      web = {  # Service name becomes container name
        image = "nginx:latest";
        ports = [  # ports: list of strings "host:container"
          "80:80"
          "443:443"
        ];
        volumes = [  # Convert relative paths to absolute /var/lib/...
          "/var/lib/myapp/data:/data"
          "/var/lib/myapp/config:/etc/nginx"
        ];
        environment = {  # environment: becomes attrset
          KEY = "value";
          ANOTHER = "value";
        };
        # env_file: becomes agenix secret (see secrets section below)
        dependsOn = [ "db" ];  # depends_on: list of container names
        # restart: handled automatically by oci-containers
      };

      db = {
        image = "postgres:15";
        volumes = [  # Named volumes become /var/lib/...
          "/var/lib/myapp/db-data:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_DB = "mydb";
        };
      };
    };

    # Create directories for volumes
    directories = [
      { path = "/var/lib/myapp/data"; mode = "0755"; }
      { path = "/var/lib/myapp/config"; mode = "0755"; }
      { path = "/var/lib/myapp/db-data"; mode = "0755"; }
    ];

    # Extract exposed ports from services that publish them
    firewall.allowedTCPPorts = [ 80 443 ];
  };
}
```

### Handling Secrets (env_file)

When you see `env_file:` in docker-compose:

1. Ask user to create agenix secret first
2. Reference it in the stack:

```nix
{
  # At top of file
  age.secrets."myapp-secrets" = {
    file = ../../../../secrets-agenix/myapp-secrets.age;
    mode = "0440";
  };

  services.containerStacks.myapp = {
    # Secret mounted in ALL containers automatically
    secrets."app-env".path = config.age.secrets."myapp-secrets".path;
    
    containers = {
      # Containers automatically get secret as env file
    };
  };
}
```

### Path Conversions

| Docker-Compose | NixOS |
|----------------|-------|
| `./data` | `/var/lib/myapp/data` |
| `./config` | `/var/lib/myapp/config` |
| `~/data` | `/var/lib/myapp/data` |
| Named volume `db-data:` | `/var/lib/myapp/db-data` |

**Pattern:** Convert all relative paths to `/var/lib/<stack-name>/...`

### Special Cases

#### Build Context (Not Supported)
```yaml
# docker-compose.yml
services:
  app:
    build: ./app  # ❌ Not directly supported
```

**Solution:** Tell user to either:
1. Use a pre-built image from a registry
2. Build with `dockerTools.buildImage` in Nix (advanced)

#### Healthchecks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**Converts to:**
```nix
containers.myapp = {
  # Add to extraOptions (note: limited support in podman)
  extraOptions = [
    "--health-cmd=curl -f http://localhost"
    "--health-interval=30s"
    "--health-timeout=10s"
    "--health-retries=3"
  ];
};
```

#### Capabilities
```yaml
cap_add:
  - NET_ADMIN
  - SYS_ADMIN
```

**Converts to:**
```nix
containers.myapp = {
  extraOptions = [
    "--cap-add=NET_ADMIN"
    "--cap-add=SYS_ADMIN"
  ];
};
```

#### Devices
```yaml
devices:
  - /dev/dri:/dev/dri
```

**Converts to:**
```nix
containers.myapp = {
  extraOptions = [
    "--device=/dev/dri:/dev/dri"
  ];
};
```

#### User/Group
```yaml
user: "1000:1000"
```

**Converts to:**
```nix
containers.myapp = {
  user = "1000:1000";
};
```

## Complete Example: Jellyfin Stack

### Input: docker-compose.yml
```yaml
version: "3"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    ports:
      - "8096:8096"
    volumes:
      - ./config:/config
      - ./cache:/cache
      - /mnt/media:/media:ro
    environment:
      JELLYFIN_PublishedServerUrl: https://jellyfin.example.com
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped

networks:
  default:
    name: jellyfin
```

### Output: jellyfin-stack.nix
```nix
{ config, ... }:

{
  services.containerStacks.jellyfin = {
    network = "jellyfin";

    containers.jellyfin = {
      image = "jellyfin/jellyfin:latest";
      ports = [ "8096:8096" ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/var/lib/jellyfin/cache:/cache"
        "/mnt/media:/media:ro"
      ];
      environment = {
        JELLYFIN_PublishedServerUrl = "https://jellyfin.example.com";
      };
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
      ];
    };

    directories = [
      { path = "/var/lib/jellyfin/config"; mode = "0755"; }
      { path = "/var/lib/jellyfin/cache"; mode = "0755"; }
    ];

    firewall.allowedTCPPorts = [ 8096 ];
  };
}
```

## Agent Workflow

1. **Receive docker-compose.yml from user**
2. **Parse the YAML** (or have user paste it)
3. **For each service:**
   - Map to `containers.<name>`
   - Convert `image`, `ports`, `volumes`, `environment`
   - Handle `depends_on`, `env_file`, special options
4. **Extract networks** → `network = "..."`
5. **Extract volumes** → `directories = [...]`
6. **Extract exposed ports** → `firewall.allowedTCPPorts`
7. **Ask about secrets** if `env_file` is present
8. **Generate the .nix file**

## Template

Use this template for all conversions:

```nix
{ config, ... }:

{
  # If secrets are needed:
  age.secrets."STACKNAME-secrets" = {
    file = ../../../../secrets-agenix/STACKNAME-secrets.age;
    mode = "0440";
  };

  services.containerStacks.STACKNAME = {
    network = "NETWORK_NAME";

    # If secrets:
    secrets."app-env".path = config.age.secrets."STACKNAME-secrets".path;

    containers = {
      SERVICE1 = {
        image = "IMAGE:TAG";
        ports = [ "HOST:CONTAINER" ];
        volumes = [ "/var/lib/STACKNAME/path:/container/path" ];
        environment = {
          KEY = "value";
        };
        dependsOn = [ "SERVICE2" ];
      };

      SERVICE2 = {
        # ...
      };
    };

    directories = [
      { path = "/var/lib/STACKNAME/dir1"; mode = "0755"; }
    ];

    firewall.allowedTCPPorts = [ PORT1 PORT2 ];
  };
}
```

## Common Patterns

### Database + App
```nix
containers = {
  app = {
    image = "myapp:latest";
    dependsOn = [ "db" ];
  };
  db = {
    image = "postgres:15";
  };
};
```

### Reverse Proxy + Services
```nix
containers = {
  nginx = {
    image = "nginx:latest";
    ports = [ "80:80" "443:443" ];
    dependsOn = [ "app1" "app2" ];
  };
  app1 = { /* ... */ };
  app2 = { /* ... */ };
};
```

### Media Stack (Arr Suite)
```nix
containers = {
  sonarr.image = "linuxserver/sonarr:latest";
  radarr.image = "linuxserver/radarr:latest";
  prowlarr.image = "linuxserver/prowlarr:latest";
  # All share same network, volumes, secrets automatically
};
```

## Testing After Conversion

Tell user to:
1. Add the stack file to imports in `podman/default.nix`
2. Run: `nixos-rebuild test --flake .#podman`
3. Check: `podman ps` to verify containers started
4. Test: Access the service ports

## Error Handling

If docker-compose uses features not supported:
- **build:** "Please use a pre-built image or ask about dockerTools.buildImage"
- **extends:** "Please inline the configuration"
- **profiles:** "Create separate stack files for each profile"
- **deploy:** "Not applicable to single-host NixOS"

---

This format is optimized for AI agents to parse and convert efficiently!
