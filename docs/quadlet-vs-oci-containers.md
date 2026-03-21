# Quadlet Standalone vs oci-containers: What Do You Actually Gain?

## TL;DR: Not Much for Your Use Case

After hands-on testing, **Quadlet standalone containers offer minimal advantages over `virtualisation.oci-containers`** for a NixOS homelab.

## The Honest Comparison

### virtualisation.oci-containers (What You Had)

```nix
virtualisation.oci-containers.containers = {
  paperless-ngx = {
    image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
    ports = [ "8000:8000" ];
    volumes = [ "/var/lib/paperless/data:/usr/src/paperless/data" ];
    environmentFiles = [ config.age.secrets."paperless-db-password".path ];
    environment = { PAPERLESS_REDIS = "redis://paperless-redis:6379"; };
    extraOptions = [ "--network=paperless" ];
    dependsOn = [ "paperless-db" "paperless-redis" ];
  };
  # ... etc
};
```

**Pros:**
- ✅ Works perfectly (port forwarding works!)
- ✅ Native NixOS module
- ✅ Clean, declarative syntax
- ✅ Managed by systemd automatically
- ✅ Well-tested and stable
- ✅ Network creation handled automatically
- ✅ Dependencies work correctly

**Cons:**
- ❌ None we've discovered!

### Quadlet Standalone (Without Pods)

```nix
environment.etc."containers/systemd/paperless-ngx.container".text = ''
  [Container]
  Image=ghcr.io/paperless-ngx/paperless-ngx:latest
  PublishPort=8000:8000
  Volume=/var/lib/paperless/data:/usr/src/paperless/data
  EnvironmentFile=${config.age.secrets."paperless-db-password".path}
  Environment=PAPERLESS_REDIS=redis://paperless-redis:6379
  Network=paperless.network
  
  [Service]
  Restart=always
'';

environment.etc."containers/systemd/paperless.network".text = ''
  [Network]
  NetworkName=paperless
'';
```

**Pros:**
- ✅ Port forwarding works (without pods)
- ✅ Native podman feature (not NixOS-specific)
- ✅ Systemd-native (podman-auto-update works)
- ✅ Slightly more "standard" (matches RHEL/Fedora patterns)

**Cons:**
- ⚠️ More verbose (need separate .network files)
- ⚠️ Duplicate secret paths in each container
- ⚠️ Less NixOS-integrated (raw text files vs proper options)
- ⚠️ Network DNS might need manual setup
- ⚠️ No built-in dependency management

## What's Actually Different?

### Under the Hood

Both `oci-containers` and Quadlet standalone create **the exact same podman containers**:

```bash
# oci-containers creates:
podman run --name paperless-ngx -p 8000:8000 ...

# Quadlet creates:
podman run --name systemd-paperless-ngx -p 8000:8000 ...
```

The only real difference is:
1. **Who generates the systemd service**: NixOS (oci-containers) vs podman's quadlet-generator
2. **File format**: Nix options vs `.container` text files

### The "Advantages" Examined

#### 1. "Quadlet is More Standard"

**Claim:** Quadlet configs work across RHEL, Fedora, etc.

**Reality:** You're on NixOS. You won't be copying configs to RHEL. And if you did, you'd need to rewrite paths anyway (`/run/agenix` doesn't exist on RHEL).

**Verdict:** ❌ Not useful for a NixOS homelab

#### 2. "Quadlet Has Auto-Update"

**Claim:** `podman auto-update` works with Quadlet labels.

**Reality:** 
- You can add `--label io.containers.autoupdate=registry` to `oci-containers.extraOptions` too
- NixOS rebuilds update containers anyway
- Auto-update breaks declarative management

**Verdict:** ❌ Not an advantage, arguably worse

#### 3. "Quadlet is Native Podman"

**Claim:** It's built into podman, so it's better maintained.

**Reality:**
- `oci-containers` just calls `podman run` - it's also using "native podman"
- NixOS maintains the wrapper, which is more useful than raw Quadlet
- Both work equally well

**Verdict:** ~ Neutral, maybe slight edge to oci-containers (NixOS integration)

#### 4. "Quadlet Has Better Systemd Integration"

**Claim:** Quadlet services integrate better with systemd.

**Reality:**
```bash
# oci-containers creates:
systemd-podman-paperless-ngx.service

# Quadlet creates:
paperless-ngx.service

# Both work identically:
systemctl status [service-name]
journalctl -u [service-name]
```

**Verdict:** ❌ No practical difference

#### 5. "Quadlet Supports Pods Better"

**Claim:** Quadlet was designed for pods!

**Reality:**
- We literally just proved pods don't work (port forwarding broken)
- `oci-containers` doesn't support pods, but pods aren't working anyway
- For multi-container apps, just use shared networks (both support this)

**Verdict:** ❌ Pods are broken, so this is irrelevant

## What You LOSE with Quadlet

### 1. **Type Safety and Validation**

```nix
# oci-containers: NixOS validates this at build time
virtualisation.oci-containers.containers.foo = {
  image = "myimage";
  ports = [ "80:80" ];  # ← NixOS checks this is valid
};

# Quadlet: Raw strings, no validation until runtime
environment.etc."containers/systemd/foo.container".text = ''
  PublishPort=not-a-valid-port  # ← Breaks at runtime!
'';
```

### 2. **Nix Expression Power**

```nix
# oci-containers: Use Nix functions
virtualisation.oci-containers.containers = lib.listToAttrs (
  map (name: {
    name = name;
    value = { image = "${name}:latest"; };
  }) [ "web" "api" "worker" ]
);

# Quadlet: Need to manually template strings (gross)
```

### 3. **Secret Integration**

```nix
# oci-containers: Clean reference
environmentFiles = [ config.age.secrets."foo".path ];

# Quadlet: Must interpolate into text
environment.etc."...".text = ''
  EnvironmentFile=${config.age.secrets."foo".path}
'';
# ↑ This works but is uglier and error-prone
```

### 4. **Dependency Management**

```nix
# oci-containers: Built-in
dependsOn = [ "db" "redis" ];

# Quadlet: Manual systemd After=
[Unit]
After=db.service redis.service
```

## Real-World Comparison

### Adding a New Container

**oci-containers:**
```nix
# Add 10 lines
virtualisation.oci-containers.containers.newapp = {
  image = "newapp:latest";
  ports = [ "3000:3000" ];
  # Done!
};
```

**Quadlet:**
```nix
# Add 15+ lines
environment.etc."containers/systemd/newapp.container".text = ''
  [Unit]
  Description=New App
  
  [Container]
  Image=newapp:latest
  PublishPort=3000:3000
  
  [Service]
  Restart=always
  
  [Install]
  WantedBy=default.target
'';
```

### Managing Secrets

**oci-containers:**
```nix
# Define secret once
age.secrets.app-password = { file = ./secret.age; };

# Use in containers
containers.app1.environmentFiles = [ config.age.secrets.app-password.path ];
containers.app2.environmentFiles = [ config.age.secrets.app-password.path ];
```

**Quadlet:**
```nix
# Define secret once
age.secrets.app-password = { file = ./secret.age; };

# Repeat the path in every container (can't use variable)
environment.etc."containers/systemd/app1.container".text = ''
  EnvironmentFile=/run/agenix/app-password  # ← Hardcoded!
'';
environment.etc."containers/systemd/app2.container".text = ''
  EnvironmentFile=/run/agenix/app-password  # ← Hardcoded again!
'';
```

## When Quadlet WOULD Be Better

- **Not on NixOS**: RHEL, Fedora, vanilla Arch
- **Root-less containers**: Quadlet has better user-level support
- **Complex pod requirements**: If pods actually worked
- **Systemd power users**: Who want custom unit options
- **Mixed management**: Some containers in Nix, some manual

## The Verdict for Your Homelab

### oci-containers Wins Because:

1. ✅ **It works** (port forwarding works!)
2. ✅ **Less code** (cleaner, more declarative)
3. ✅ **Better Nix integration** (type-safe, functional)
4. ✅ **Easier to maintain** (fewer files, less boilerplate)
5. ✅ **No loss of features** (does everything you need)

### Quadlet's "Advantages" Don't Matter Because:

1. ❌ Cross-distro compatibility: You're on NixOS
2. ❌ Pods: They're broken anyway
3. ❌ "More standard": NixOS options are the standard on NixOS
4. ❌ Auto-update: You rebuild declaratively
5. ❌ Native podman: Both use podman equally

## Recommendation

**Stick with `virtualisation.oci-containers`.**

It's:
- Simpler
- More powerful (Nix expressions)
- Better tested on NixOS
- Actually working (unlike our Quadlet experiments)
- The NixOS-native way

### What We Learned From This Exercise

1. **Arion**: Broken port forwarding (docker-compose + podman-socket mismatch)
2. **Quadlet with pods**: Broken port forwarding (pod networking quirks)
3. **oci-containers**: Just works™

**The simplest solution was the best all along.**

## Migration Back

Since we've proven oci-containers is better, I can:

1. Revert to your original working configuration
2. Keep the Arion/Quadlet code as reference in git history
3. Document what we learned (this file!)
4. Move on to actually using paperless instead of fighting container orchestration

Want me to revert back to oci-containers?

---

## Appendix: The Only Real Reason to Use Quadlet

If you ever want **rootless containers** (running as a non-root user), Quadlet is better because it integrates with user systemd services cleanly.

But for a homelab where containers run as root (which is fine), oci-containers is superior.
