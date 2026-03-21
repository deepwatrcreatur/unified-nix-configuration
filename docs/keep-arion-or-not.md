# Should You Keep Arion Alongside Quadlet?

## Short Answer: No

**Don't run two container management systems in parallel.** Use Quadlet exclusively and ask a coding agent to convert docker-compose files when needed.

## Why Not Both?

### 1. **Conflicts & Confusion**
- Both try to manage the same podman daemon
- Port conflicts (both might try to bind 8000)
- Network conflicts (overlapping CNI configurations)
- iptables rule conflicts (we just saw this!)
- Which system is managing which container?

### 2. **Maintenance Burden**
- Two systems to update
- Two sets of configurations to maintain
- Two potential points of failure
- Need to remember which stack uses which system

### 3. **Resource Waste**
- Arion's Haskell binary always loaded
- Docker-compose process overhead
- Duplicate network namespaces
- Extra complexity for no benefit

### 4. **It's Not Actually Easier**

**The Promise:** "I can just run docker-compose files directly!"

**The Reality:**
- Docker-compose files rarely work as-is on NixOS
- Paths are different (`/var/lib` vs `/mnt/data`)
- Secret management is different (agenix vs `.env` files)
- You need to adjust them anyway
- Port forwarding might not work (as we just saw)

## The Better Workflow

### When You Find a Docker-Compose File Online:

```bash
# Don't try to run it directly - convert it!

# 1. Save the docker-compose.yml
curl https://example.com/docker-compose.yml > /tmp/stack.yml

# 2. Ask a coding agent to convert it
gh copilot "Convert this docker-compose.yml to NixOS Quadlet format: 
- Use environment.etc for .container/.pod/.network files
- Integrate with agenix for secrets
- Follow the pattern in hosts/nixos-lxc/podman/stacks/paperless-quadlet.nix"

# 3. Review and adjust
# - Fix paths for NixOS
# - Wire up secrets
# - Test

# 4. Deploy
nixos-rebuild switch --flake .#podman
```

### Example Conversion

**Docker Compose:**
```yaml
services:
  app:
    image: myapp:latest
    ports:
      - "3000:3000"
    environment:
      DB_HOST: db
    volumes:
      - ./data:/data
```

**Quadlet (30 seconds of work):**
```nix
environment.etc."containers/systemd/myapp.container".text = ''
  [Container]
  Image=myapp:latest
  PublishPort=3000:3000
  Environment=DB_HOST=db
  Volume=/var/lib/myapp/data:/data
'';
```

**Same simplicity, better integration!**

## What About Complex Stacks?

### "But my docker-compose has 15 services!"

Quadlet handles this fine:
```nix
# One .pod file
environment.etc."containers/systemd/mystack.pod".text = ...

# 15 .container files (one per service)
environment.etc."containers/systemd/service1.container".text = ...
environment.etc."containers/systemd/service2.container".text = ...
# ... etc
```

You can even generate them programmatically:
```nix
let
  services = [ "web" "api" "worker" "cache" ];
in {
  environment.etc = lib.listToAttrs (map (name: {
    name = "containers/systemd/${name}.container";
    value.text = ''
      [Container]
      Image=${name}:latest
      Pod=mystack.pod
    '';
  }) services);
}
```

## What About Special Docker-Compose Features?

### "Docker-compose has advanced features!"

Most are available in Quadlet:

| Docker-Compose Feature | Quadlet Equivalent |
|------------------------|-------------------|
| `depends_on` | `After=` in `[Unit]` section |
| `restart: always` | `Restart=always` in `[Service]` |
| `networks` | `.network` files + `Network=` |
| `volumes` | `Volume=` directives |
| `env_file` | `EnvironmentFile=` |
| `healthcheck` | `HealthCmd=`, `HealthInterval=` |
| `build` | Use `dockerTools.buildImage` in Nix |

### "But docker-compose has build!"

Use Nix instead (better anyway):
```nix
pkgs.dockerTools.buildImage {
  name = "myapp";
  config.Cmd = [ "${myapp}/bin/myapp" ];
}
```

## Exceptions (Still Use Quadlet)

### "What if I really need docker-compose?"

Then use it **directly**, not through Arion:

```nix
# Just run docker-compose as a systemd service
systemd.services.my-compose-stack = {
  script = ''
    cd /var/lib/my-stack
    ${pkgs.docker-compose}/bin/docker-compose up
  '';
  wantedBy = [ "multi-user.target" ];
};
```

No need for Arion's translation layer!

## Recommendation

### ✅ Do This:
1. **Remove Arion** from flake inputs (cleaner dependency tree)
2. **Use Quadlet** for all container management
3. **Keep examples** (paperless-arion.nix) as reference
4. **Ask agents** to convert docker-compose when needed
5. **Document patterns** in your repo for future conversions

### ❌ Don't Do This:
1. Run Arion and Quadlet together
2. Keep Arion "just in case"
3. Try to run docker-compose files directly
4. Maintain two parallel systems

## The Agent Conversion Promise

**Reality check:** Converting docker-compose to Quadlet is:
- ✅ Fast (< 5 minutes with an agent)
- ✅ Reliable (agent can see your existing patterns)
- ✅ Better integrated (NixOS paths, secrets, etc.)
- ✅ One-time cost

**vs. Keeping Arion:**
- ❌ Ongoing maintenance
- ❌ Potential conflicts
- ❌ Extra complexity
- ❌ The port forwarding doesn't even work!

## Conclusion

**Remove Arion.** Trust that:
1. Quadlet handles everything you need
2. Coding agents can convert docker-compose files quickly
3. Simpler is better
4. You just proved Arion has issues (port forwarding)

**The migration we just did taught us:**
- Arion looked promising
- Reality had port forwarding bugs
- Simpler (Quadlet) is better
- Don't keep broken tools "just in case"

---

**Decision:** I've already removed Arion from the flake in this commit. If you find a compelling reason to keep it later, we can always add it back. But give Quadlet a fair shot first - it's what podman developers actually recommend.
