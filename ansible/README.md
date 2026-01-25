# Ansible Setup for Proxmox Hosts

This directory contains Ansible playbooks for automating Nix and home-manager setup on Proxmox hosts.

## Quick Start

```bash
# Install Ansible (if not already installed)
pip install ansible

# Run the playbook
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml
```

## Directory Structure

```
ansible/
├── inventory/
│   └── proxmox.ini          # Host inventory
├── group_vars/
│   └── proxmox.yml          # Variables for proxmox group
└── playbooks/
    └── setup-proxmox-root.yml # Main playbook
```

## Configuration

### Inventory (`inventory/proxmox.ini`)

Add your Proxmox hosts:

```ini
[proxmox]
10.10.11.47 ansible_user=root
10.10.11.48 ansible_user=root
```

### Variables (`group_vars/proxmox.yml`)

Customize variables in `group_vars/proxmox.yml`:

| Variable | Default | Description |
|----------|----------|-------------|
| `cache_build_server_host` | `cache-build-server` | Hostname of cache server |
| `cache_build_server_port` | `5001` | Port for cache server |
| `config_repo_url` | Required | Git repository URL |
| `config_repo_path` | `/root/flakes/unified-nix-configuration` | Local path for repo |
| `home_manager_output` | `proxmox-root` | Home Manager output name |

## Playbook Steps

The `setup-proxmox-root.yml` playbook performs:

1. ✅ **Install Determinate Nix** - Uses the official installer script
2. ✅ **Configure cache-build-server** - Adds as a substituter for faster builds
3. ✅ **Clone configuration repo** - Pulls your flake configuration
4. ✅ **Remove conflicting files** - Cleans up existing shell configs
5. ✅ **Verify and fix profile symlinks** - Ensures `.nix-profile` points to home-manager
6. ✅ **Activate home-manager** - Applies `proxmox-root` configuration
7. ✅ **Verify installation** - Checks that everything is working correctly

## Usage Examples

### Run on single host

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --limit 10.10.11.47
```

### Run on all proxmox hosts

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml
```

### Check mode (dry run)

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --check
```

### Verbose output

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml -v
```

### Skip specific tasks
```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --skip-tags news
```

## Troubleshooting

### Atuin "command not found" Error

If you see `atuin: command not found` after SSH login:

#### Problem
The `.nix-profile` symlink points to system profile instead of to home-manager profile:
```bash
# Wrong (causes error)
/root/.nix-profile -> /nix/var/nix/profiles/per-user/root/profile

# Correct
/root/.nix-profile -> /nix/var/nix/profiles/per-user/root/home-manager
```

#### Solution 1: Manual Quick Fix

SSH into the host and fix the symlink:

```bash
ln -sf /nix/var/nix/profiles/per-user/root/home-manager ~/.nix-profile
exec bash
```

#### Solution 2: Re-run Home-Manager Activation

```bash
cd /root/flakes/unified-nix-configuration
/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
```

#### Solution 3: Ansible Auto-Fix

The playbook now automatically detects and fixes this issue. Re-run:

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml
```

#### Verification

After fixing, verify that the shell works:

```bash
# Check that profile is correct
readlink ~/.nix-profile
# Should output: /nix/var/nix/profiles/per-user/root/home-manager

# Verify atuin is available
which atuin
atuin --version

# Check that PATH includes home-manager
echo $PATH | grep home-manager
```

## Troubleshooting

### Connection issues

```bash
# Test SSH connection
ansible proxmox -i inventory/proxmox.ini -m ping

# Check if host is reachable
ansible proxmox -i inventory/proxmox.ini -m shell -a "hostname"
```

### Home-manager activation fails

If activation fails, the playbook will continue and display errors. You can then:

1. SSH into the host and run manually:
   ```bash
   cd /root/flakes/unified-nix-configuration
   nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
   ```

2. Check home-manager logs:
   ```bash
   cat ~/.local/state/home-manager/home-manager.log
   ```

3. Run home-manager doctor:
   ```bash
   /root/.nix-profile/bin/home-manager doctor
   ```

### Cache-build-server not working

Verify the cache server is accessible:

```bash
ansible proxmox -i inventory/proxmox.ini -m shell -a "curl -s http://cache-build-server:5001"
```

If it's not accessible, update `cache_build_server_host` in `group_vars/proxmox.yml`.

### Idempotency Issues

The playbook is designed to be idempotent (can run multiple times safely). However:

- Nix installation only runs if `/nix` doesn't exist
- Git repo is updated if it exists
- Cache-build-server config is added if not present

## Requirements

### Control Machine
- Python 3.6+
- Ansible 2.9+
- SSH access to target hosts

### Target Machines
- Debian/Ubuntu-based system (Proxmox VE)
- Root SSH access
- Internet access (for Nix installation and package downloads)
- Access to cache-build-server (optional but recommended)

## Advanced Usage

### Custom SSH key

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --private-key ~/.ssh/my_key
```

### Custom inventory file

```bash
ansible-playbook -i /path/to/custom.ini playbooks/setup-proxmox-root.yml
```

### Override variables inline

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml \
  -e "config_repo_url=https://github.com/user/repo.git" \
  -e "home_manager_output=my-output"
```

## Related Documentation

- [Proxmox Root Setup Guide](../docs/proxmox-root-setup.md) - Manual setup steps
- [Ansible Documentation](https://docs.ansible.com/) - General Ansible usage
- [Determinate Nix](https://determinate.systems/) - Nix distribution used

## Contributing

When adding new tasks to the playbook:

1. Ensure tasks are idempotent where possible
2. Use proper handlers (e.g., `restart nix-daemon`)
3. Add variables to `group_vars/proxmox.yml` instead of hardcoding
4. Update this README with new configuration options
5. Test on a single host first (`--limit`)
