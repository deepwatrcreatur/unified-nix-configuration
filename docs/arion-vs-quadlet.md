# Arion vs Quadlet: Which is Better for NixOS Podman?

## TL;DR: Quadlet is Better for NixOS + Podman

After testing, **Quadlet** (systemd-native podman management) is the better choice for NixOS + Podman.

## Comparison

| Feature | Arion | Quadlet |
|---------|-------|---------|
| **Integration** | Docker-compose compatibility layer | Native systemd + podman |
| **Port Forwarding** | ⚠️ Issues with podman-socket | ✅ Works reliably |
| **Syntax** | Docker-compose YAML/Nix | Systemd unit-like (simpler) |
| **NixOS Support** | Good (external project) | ✅ Excellent (built into podman) |
| **Maintenance** | External dependency | ✅ Maintained by podman team |
| **Overhead** | Requires docker-compose translation | ✅ Direct systemd units |
| **Networking** | CNI via docker-compose | ✅ Native netavark/CNI |
| **Dependencies** | Haskell binary + compose | ✅ Just podman |

## The Port Forwarding Problem

### What's Happening

Arion uses `docker-compose` which expects Docker's networking model. When using `podman-socket` (podman pretending to be docker), port forwarding doesn't work correctly because:

1. Docker-compose creates iptables rules expecting Docker's network namespace model
2. Podman uses a different network backend (netavark)
3. The translation layer doesn't handle port forwarding properly
4. Multiple conflicting DNAT rules get created

### Why It Worked Before

The old `virtualisation.oci-containers` configuration used **native podman** without the docker-compose translation layer, so port forwarding worked correctly.

## What is Quadlet?

**Quadlet** is podman's official way to manage containers via systemd. It's been part of podman since 4.4 (2023).

### How Quadlet Works

You write `.container`, `.volume`, `.network` files (like systemd units) and systemd-generator converts them to proper systemd services.

### Example: Paperless with Quadlet

```nix
# Much simpler than both Arion and manual oci-containers!
systemd.services."paperless-ngx-pod" = {
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  script = ''
    ${pkgs.podman}/bin/podman pod create \
      --name paperless \
      --network paperless \
      --publish 8000:8000
  '';
  wantedBy = [ "multi-user.target" ];
};

# Or even simpler with quadlet files:
environment.etc."containers/systemd/paperless.pod".text = ''
  [Pod]
  PodmanArgs=--infra-name=paperless-infra
  Network=paperless.network
  PublishPort=8000:8000
'';

environment.etc."containers/systemd/paperless-ngx.container".text = ''
  [Container]
  Image=ghcr.io/paperless-ngx/paperless-ngx:latest
  Pod=paperless.pod
  Volume=/var/lib/paperless/data:/usr/src/paperless/data
  Volume=/var/lib/paperless/consume:/usr/src/paperless/consume
  EnvironmentFile=/run/agenix/paperless-db-password
  Environment=PAPERLESS_REDIS=redis://localhost:6379
  Environment=PAPERLESS_DBHOST=localhost
  
  [Service]
  Restart=always
'';

environment.etc."containers/systemd/paperless-db.container".text = ''
  [Container]
  Image=postgres:15
  Pod=paperless.pod
  Volume=/var/lib/paperless/pgdata:/var/lib/postgresql/data
  EnvironmentFile=/run/agenix/paperless-db-password
  Environment=POSTGRES_DB=paperless_user
  Environment=POSTGRES_USER=paperless_user
  
  [Service]
  Restart=always
'';
```

## Why Quadlet Wins

### 1. **It Just Works™**
- No translation layers
- No docker-compose compatibility issues
- Port forwarding works correctly
- Native podman networking

### 2. **Simpler**
- Familiar systemd syntax
- No need to learn docker-compose peculiarities
- Direct mapping to podman concepts
- Less abstraction = less magic = fewer bugs

### 3. **Better NixOS Integration**
- Podman is first-class in NixOS
- No external dependencies
- Standard systemd unit management
- Works with existing NixOS patterns

### 4. **More Efficient**
- No Haskell binary (Arion)
- No docker-compose process
- Direct systemd → podman
- Lower memory footprint

### 5. **Future-Proof**
- Maintained by Red Hat/podman team
- Part of podman itself
- Won't bit-rot like external projects
- Growing ecosystem

## When to Use Each

### Use Quadlet When:
- ✅ Running on NixOS (you are!)
- ✅ Using podman (you are!)
- ✅ Want reliable port forwarding (you do!)
- ✅ Prefer simpler, native solutions
- ✅ Want to minimize dependencies

### Use Arion When:
- Converting complex docker-compose files
- Need to build custom images from Nix
- Running actual Docker (not podman)
- Have complex inter-service dependencies that docker-compose handles well

### Use Neither (oci-containers) When:
- Just a few simple containers
- Don't need pod grouping
- Happy with current NixOS options

## Recommendation

**Migrate to Quadlet.** It's:
1. Simpler than both Arion and manual oci-containers
2. More reliable (fixes your port issue)
3. Native to podman/systemd
4. Better long-term maintenance

## Migration Path

1. Keep Arion config as reference
2. Convert to Quadlet .container files
3. Test port forwarding works
4. Remove Arion dependency
5. Enjoy simpler, working setup

## References

- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Quadlet Tutorial](https://www.redhat.com/sysadmin/quadlet-podman)
- [NixOS Quadlet Examples](https://github.com/search?q=quadlet+nixos&type=code)
