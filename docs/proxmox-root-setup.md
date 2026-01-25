# Proxmox Root Setup Guide

This guide covers setting up the `proxmox-root` home-manager configuration on a new Proxmox host.

## Prerequisites

- Proxmox VE host
- SSH access to the host
- `unified-nix-configuration` repo cloned on a build machine (phoenix, local machine, or the host itself)
- `cache-build-server` running and accessible on the network

## Initial Setup

### 1. Clone the Configuration Repo

SSH into the Proxmox host and clone the repo:

```bash
ssh root@<proxmox-host>
cd /root
git clone <your-repo-url> flakes/unified-nix-configuration
```

### 2. Configure Nix Substituters

Add the cache-build-server as a substituter to speed up builds:

```bash
cat >> /etc/nix/nix.conf << 'EOF'
extra-substituters = http://cache-build-server:5001
extra-trusted-substituters = http://cache-build-server:5001
EOF

systemctl restart nix-daemon
```

This enables fetching pre-built packages from your cache-server, dramatically reducing build times.

## Deployment Methods

### Method 1: Direct Deployment (Recommended)

Build and activate directly on the Proxmox host:

```bash
cd /root/flakes/unified-nix-configuration
nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
```

**Pros:** Simple, no intermediate steps
**Cons:** Uses CPU on Proxmox host for first-time builds

### Method 2: Build Remotely (Faster)

Build on a more powerful machine (e.g., `phoenix`) and copy to target:

#### From phoenix/build machine:

```bash
cd /path/to/flakes/unified-nix-configuration
nix build .#homeConfigurations.proxmox-root.activationPackage
```

#### Copy closure to target:

```bash
nix copy --to ssh://root@<proxmox-host> result
```

Or pipe closure via stdin:

```bash
nix path-info -r result | nix copy --to ssh://root@<proxmox-host> --stdin
```

#### Activate on target:

```bash
ssh root@<proxmox-host>
/root/.nix-profile/bin/home-manager switch --flake /root/flakes/unified-nix-configuration#proxmox-root
```

### Method 3: Using deploy-rs (Best for Multiple Hosts)

If you have `deploy-rs` set up, you can deploy with a single command:

```bash
deploy .#proxmox-root
```

See the deploy-rs documentation for setup instructions.

## Troubleshooting

### File Clobber Errors

On first run, you may see errors about files being clobbered:

```
Existing file '/root/.profile' would be clobbered
Existing file '/root/.bashrc' would be clobbered
Existing file '/root/.ssh/config' would be clobbered
```

**Solution:** Remove the conflicting files (this is a fresh setup):

```bash
rm -f /root/.profile /root/.bashrc /root/.ssh/config
```

Then re-run the activation command.

### Build Taking Too Long

If builds are slow on the Proxmox host:

1. **Check cache-server is configured:**

   ```bash
   cat /etc/nix/nix.conf | grep cache-build-server
   ```

2. **Use Method 2** (build remotely) to offload compilation

3. **Verify cache-server is accessible:**

   ```bash
   curl http://cache-build-server:5001
   ```

### Unknown Setting Warnings

You may see warnings like:

```
warning: unknown setting 'eval-cores'
warning: unknown setting 'lazy-trees'
```

These are harmless - they come from experimental Nix features that may not be available in your version.

## Verification

After successful activation, verify the setup:

```bash
# Check home-manager version
home-manager --version

# Check shell is configured correctly
echo $SHELL

# Test key tools
fish --version
fnox --version
```

## Next Steps

- Read the news: `home-manager news`
- Explore the configuration in `home-manager/proxmox-root.nix`
- Customize the configuration for your needs

## Related Documentation

- [Ubuntu/Debian Nix Setup](./ubuntu-debian-nix-setup.md) - Initial Nix installation
- [Attic Server Setup](./attic-server-setup.md) - Cache server configuration
