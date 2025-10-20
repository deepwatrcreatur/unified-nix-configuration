# Nix Configuration for Ubuntu/Debian Systems

This guide helps you configure Nix on Ubuntu/Debian systems to use the cache-build-server for binary caches and remote builds.

## Prerequisites

- Nix installed on your Ubuntu/Debian system
- SSH access to cache-build-server configured
- Attic client token available (from SOPS or obtained from the server)

## Configuration Files

### 1. System-level Configuration

Create or edit `/etc/nix/nix.conf` (requires root/sudo):

```conf
# Experimental features
experimental-features = nix-command flakes impure-derivations ca-derivations

# Binary cache configuration
substituters = http://cache-build-server:5001/cache-local https://cache.nixos.org
trusted-public-keys = cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=

# Remote builders (optional but recommended for faster builds)
builders = ssh://deepwatrcreatur@cache-build-server x86_64-linux - 8 1 big-parallel
builders-use-substitutes = true

# Trusted users (allows using nix with --option and remote builders)
trusted-users = root @wheel deepwatrcreatur

# Performance settings
max-jobs = auto
cores = 0
download-buffer-size = 1048576000
http-connections = 50

# Build settings
keep-outputs = true
keep-derivations = true
show-trace = true
warn-dirty = false
```

**Apply changes:**
```bash
sudo systemctl restart nix-daemon
```

### 2. User-level Cache Authentication

Create `~/.config/nix/netrc` for Attic cache authentication:

```bash
mkdir -p ~/.config/nix
chmod 700 ~/.config/nix
```

Create `~/.config/nix/netrc`:
```
machine cache-build-server
password YOUR_ATTIC_JWT_TOKEN_HERE
```

**Set proper permissions:**
```bash
chmod 600 ~/.config/nix/netrc
```

**To get your JWT token:**
- From SOPS: `cat ~/.config/sops/attic-client-token`
- Or generate one on the cache server

### 3. Optional: User-level Configuration Override

If you don't have root access, create `~/.config/nix/nix.conf`:

```conf
experimental-features = nix-command flakes impure-derivations ca-derivations
substituters = http://cache-build-server:5001/cache-local https://cache.nixos.org
trusted-public-keys = cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
netrc-file = /home/deepwatrcreatur/.config/nix/netrc

# Note: User-level config cannot configure remote builders
# Remote builders require system-level configuration
```

## SSH Configuration for Remote Builds

If using remote builders, configure SSH access to cache-build-server:

**Create/edit `~/.ssh/config`:**
```
Host cache-build-server
    HostName cache-build-server  # or IP address
    User deepwatrcreatur
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

**Test SSH access:**
```bash
ssh cache-build-server echo "Connection successful"
```

## Verification

### Test Binary Cache Access

```bash
# Check if cache is reachable
curl --netrc-file ~/.config/nix/netrc http://cache-build-server:5001/cache-local/nix-cache-info

# Should output:
# WantMassQuery: 1
# StoreDir: /nix/store
# Priority: 41
```

### Test Nix Configuration

```bash
# Check substituters
nix config show | grep substituters

# Should include: http://cache-build-server:5001/cache-local
```

### Test Remote Build (if configured)

```bash
# Force a remote build
nix build --builders 'ssh://deepwatrcreatur@cache-build-server' nixpkgs#hello

# Check remote builder status
nix config show | grep builders
```

## Troubleshooting

### Cache authentication fails

- Verify netrc file exists and has correct permissions (600)
- Check token is valid: `curl -H "Authorization: Bearer $(cat ~/.config/nix/netrc | grep password | cut -d' ' -f2)" http://cache-build-server:5001/`
- Ensure hostname resolves: `ping cache-build-server`

### Remote builds not working

- Verify SSH access: `ssh cache-build-server nix --version`
- Check SSH key is added: `ssh-add -l`
- Ensure user is in trusted-users on the server
- Check nix-daemon is running: `systemctl status nix-daemon`

### Cache not being used

- Check substituters order (cache-build-server should be first)
- Verify public key is trusted
- Check network connectivity to cache server
- Look at nix build logs for substituter attempts: `nix build --debug ...`

## Updates

When the cache public key changes, update the `trusted-public-keys` line in your nix.conf with the new key from:
```bash
attic cache info cache-build-server:cache-local | grep "Public Key"
```

## Related Files

- This configuration matches:
  - `modules/common/nix-settings.nix` (NixOS system-level)
  - `modules/nixos/nix-settings-lxc.nix` (LXC containers)
  - `modules/home-manager/common/nix-user-config.nix` (Determinate Nix user-level)
