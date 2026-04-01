# Ansible Playbooks for Unified Nix Configuration

Ansible automation for rebuilding all hosts managed by this flake.

## Prerequisites

- Ansible installed (`nix-shell -p ansible` or system package)
- SSH access to all target hosts
- Flake repo cloned on each target host

## Inventory

Edit `inventory/hosts.yml` to configure your hosts. Hosts are grouped by rebuild type:

| Group | Rebuild Command | Hosts |
|-------|-----------------|-------|
| `nixos` | `nixos-rebuild switch` | router, homeserver, workstation, attic-cache |
| `nixos_inference` | `nixos-rebuild switch` | inference1, inference2, inference3 |
| `darwin` | `darwin-rebuild switch` | hackintosh, macminim4 |
| `proxmox` | `home-manager switch` | pve-lattitude, pve-rog, pve-strix, pve-tomahawk, pve-z170 |

## Playbooks

### rebuild-all.yml

Pulls latest changes and rebuilds all hosts.

```bash
# Rebuild everything
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml

# Limit to specific group
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml --limit nixos

# Limit to specific hosts
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml --limit "router,homeserver"

# Skip git pull (just rebuild with current state)
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml -e skip_git_pull=true

# Use 'test' instead of 'switch'
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml -e rebuild_action=test

# Dry run
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml --check
```

### rebuild-cache-first.yml

Rebuilds attic-cache first to ensure the binary cache is updated, then rebuilds all other hosts (3 at a time).

```bash
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-cache-first.yml
```

### update-proxmox.yml

Pulls latest changes and runs `home-manager switch` on the 5 Proxmox hosts only.
This is the simplest playbook to point Semaphore at for routine PVE updates.

```bash
# Update all Proxmox hosts
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml

# Update just one or two Proxmox hosts
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml --limit pve-z170
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml --limit "pve-rog,pve-strix"

# Skip git pull and only re-run Home Manager
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml -e skip_git_pull=true
```

### git-pull-only.yml

Just pulls the latest changes without rebuilding. Useful for staging updates.

```bash
ansible-playbook -i inventory/hosts.yml playbooks/git-pull-only.yml
```

### setup-secrets.yml

Bootstraps decrypted cache and token files needed for Nix and git auth.

For Proxmox hosts, this now also writes `/nix/var/determinate/netrc` directly so
`cache.nix-ci.com` and `attic-cache` auth works even if `proxmox-root`
Home Manager activation is blocked by an unrelated package conflict.

```bash
ansible-playbook -i inventory/hosts.yml playbooks/setup-secrets.yml --limit proxmox
```

### bootstrap-nixos-router.yml

Bootstraps `router` or `router-backup` from a NixOS live ISO using
`nixos-anywhere`. Handles SSH agent exhaustion and the optional attic-cache
pre-configuration needed when DNS is unavailable (which it is when you're
installing the machine that provides DNS).

```bash
# Basic install
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-nixos-router.yml \
  -e install_target=10.10.21.82 -e flake_target=router

# With attic-cache by IP (avoids building everything locally, saves ~30 min)
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-nixos-router.yml \
  -e install_target=10.10.21.82 -e flake_target=router -e use_attic_cache=true
```

See `docs/router-nixos-anywhere-lessons.md` for the full lessons-learned
writeup, including management network access after install.

### bootstrap-nixos-inference.yml

Bootstraps `inference1`, `inference2`, or `inference3` from a NixOS live ISO
using `nixos-anywhere`. This is the first-install path, not the day-2 rebuild
path.

For Proxmox, use plain `OVMF` on `q35` with the installer ISO first and the
system disk second. Do not use Secure Boot, pre-enrolled keys, or a persistent
`efidisk0` for these inference VMs.

It runs from the control machine and updates the repo working tree with:

- refreshed `hardware-configuration.nix`
- `ssh-keys/agenix-machine-identities/<host>.pub`
- rekeyed `.age` files when recipients changed

```bash
# Standard install
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-nixos-inference.yml --limit inference1

# With attic-cache by IP (when DNS/router is unavailable)
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap-nixos-inference.yml \
  --limit inference1 -e use_attic_cache=true
```

See `../docs/inference-vm-bootstrap.md` for the full workflow.

## Git Handling

The playbooks automatically handle common git issues:

- **flake.lock conflicts**: Automatically reset before pulling (local evaluations may update it)
- **Other local changes**: Stashed with timestamp, can be restored with `git stash pop`
- **Fast-forward only**: Uses `--ff-only` to prevent merge commits

## Adding New Hosts

1. Add host to appropriate group in `inventory/hosts.yml`
2. Set `ansible_host` (IP or DNS name)
3. Set `flake_target` (for nixos/darwin) or `home_manager_target` (for home-manager only)
4. Ensure the repo is cloned on the target host

Example for a new NixOS host:
```yaml
nixos:
  hosts:
    my-new-host:
      ansible_host: 10.10.10.100
      flake_target: my-new-host
```

## Proxmox Hosts

Proxmox hosts use home-manager only (not full NixOS). They connect as root and use a shared `proxmox-root` home-manager configuration.

The `proxmox-host-configuration` repo contains additional Proxmox-specific playbooks for:
- Bootstrap/initial setup
- APT proxy configuration
- Proxmox-specific tasks

### Adding a New Proxmox Host

The playbooks assume the host is already registered as an agenix recipient. Do this **in the repo first**, before touching the host:

1. Get the SSH host key: `ssh-keyscan -t ed25519 <ip>`
2. Add `ssh-keys/agenix-machine-identities/<hostname>.pub`
3. Add the host to `lib/hosts.nix`, `ansible/inventory/hosts.yml`, `secrets.nix` (`atticClientHosts`), and `lib/remote-builder.nix` (`nonNixosHosts`)
4. Rekey: `nix run github:ryantm/agenix -- --rekey`
5. Commit and push

Then bootstrap the host (see `docs/proxmox-root-setup.md` for the full sequence) and run:

```bash
# Decrypt secrets (uses machine SSH host key, not SOPS age key)
ansible-playbook -i inventory/hosts.yml playbooks/setup-secrets.yml --limit <hostname>

# Apply home-manager (writes nix.conf substituters before building)
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml --limit <hostname>
```

## Troubleshooting

### SSH Connection Issues
```bash
# Test connectivity
ansible -i inventory/hosts.yml all -m ping

# Verbose SSH debugging
ansible-playbook -i inventory/hosts.yml playbooks/rebuild-all.yml -vvv
```

### Repo Not Found
Ensure the flake repo is cloned on the target host:
```bash
ssh hostname "git clone git@github.com:user/unified-nix-configuration.git ~/flakes/unified-nix-configuration"
```

### Rebuild Failures
Check the last 30 lines of output shown in the playbook. For full logs:
```bash
ssh hostname "cd ~/flakes/unified-nix-configuration && sudo nixos-rebuild switch --flake .#hostname"
```
