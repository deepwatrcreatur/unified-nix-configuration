# Utility Scripts

This directory contains reusable scripts for managing the unified-nix-configuration infrastructure.

## git-ssh-doctor.sh

**Purpose**: Read-only diagnostics for Git SSH signing, SSH agent state, and
GitHub SSH transport.

**Checks**:
- `gpg.format`, `commit.gpgsign`, `tag.gpgsign`, `user.signingkey`
- `gpg.ssh.allowedSignersFile` presence
- `SSH_AUTH_SOCK` presence and socket state
- `ssh-add -l` loaded-identity state
- effective `ssh -G github.com` identity settings
- optional live GitHub SSH probe
- optional `git log --show-signature` inspection

**Usage**:
```bash
./scripts/git-ssh-doctor.sh
./scripts/git-ssh-doctor.sh --no-github-probe
./scripts/git-ssh-doctor.sh --no-git-log
```

**How to read it**:
- `FAIL signing-config`: Git is not configured for SSH signing correctly.
- `WARN ssh-add`: the SSH agent is reachable but has no identities loaded.
- `FAIL github-probe` with `PASS signing-config`: signing config exists, but
  GitHub SSH auth/transport is failing separately.

## ssh-bash.sh

**Purpose**: Force remote commands through Bash even when the account's default
shell is `fish` or another non-POSIX shell.

**Why it exists**:
- agents and automation frequently rely on `bash -lc`, heredocs, and POSIX
  quoting
- remote login shells like `fish` can parse SSH commands before Bash ever runs
- this wrapper enters `/run/current-system/sw/bin/bash` on NixOS hosts and
  falls back to `/bin/bash` or `bash` elsewhere

**Usage**:
```bash
ssh-bash router
ssh-bash -o BatchMode=yes -o ConnectTimeout=5 router -- systemctl status kea-dhcp4-server
ssh-bash router -- "journalctl -u kea-dhcp-ddns-server --since '10 min ago' | tail -n 40"
cat ./script.sh | ssh-bash router
```

**Behavior**:
- interactive stdin: opens a remote login Bash shell
- piped stdin with no command: runs the piped script via remote Bash
- command arguments after `--`: runs them through remote `bash -lc`

**Installed command**:
- Home Manager installs `ssh-bash`
- shell alias `sshb` points to `ssh-bash`

## setup-hdd-logging.sh

**Purpose**: Configure fault-tolerant logging to spinning disk (HDD) for any Linux host.

**Features**:
- ✅ Boots normally even if HDD fails (`nofail` option)
- ✅ Automatic fallback to primary disk
- ✅ Systemd journal on HDD with bind mount
- ✅ Configurable journal size limits
- ✅ Automatic fstab backup

**Usage**:
```bash
sudo ./setup-hdd-logging.sh <mount-point> <device-uuid> [max-journal-size]
```

**Example**:
```bash
# Find your HDD UUID
lsblk -o NAME,UUID,SIZE
blkid

# Run setup
sudo ./setup-hdd-logging.sh /mnt/logs 947be3a2-edf8-49f0-85c9-329ae56a9bf1 10G
```

**Default Values**:
- Mount point: `/mnt/logs`
- Max journal size: `10G`
- Device timeout: `5 seconds`

**What it does**:
1. Backs up `/etc/fstab`
2. Adds/updates fstab entry with `nofail` option
3. Creates log directory structure
4. Configures systemd-journald
5. Creates bind mount for `/var/log/journal`
6. Enables and starts services

**Tested on**:
- Proxmox VE 8.x (Debian-based)
- NixOS 25.11 (via similar configuration in `hosts/nixos/router/`)
- Debian 12
- Ubuntu 22.04+

**Safety Features**:
- Automatic fstab backup before changes
- Non-destructive (won't overwrite existing logs)
- Graceful fallback to SSD if HDD unavailable
- Only waits 5 seconds for HDD during boot
- Can be safely re-run (idempotent)

**Directory Structure Created**:
```
/mnt/logs/
├── journal/        - systemd journal (bind mounted to /var/log/journal)
├── system/         - general system logs
├── services/       - application service logs
└── apt/            - package manager logs
```

**Verification**:
```bash
# Check mount
df -h /mnt/logs
mount | grep logs

# Check journal
journalctl --disk-usage
ls -la /var/log/journal

# Check fstab
grep '/mnt/logs' /etc/fstab
```

**Rollback**:
```bash
# Find backup
ls -la /etc/fstab.backup-*

# Restore
sudo cp /etc/fstab.backup-YYYYMMDD-HHMMSS /etc/fstab

# Remount
sudo systemctl daemon-reload
sudo umount /mnt/logs
sudo mount -a
```

**Use Cases**:
- Preserve SSD lifespan on routers
- Archive logs on larger, cheaper spinning disks
- Centralized logging on homelab servers
- High-write workloads (databases, proxies, etc.)

**Current Deployments**:
- ✅ `router`: NixOS router (10GB HDD for logs) - uses native NixOS config
- 🔄 Can be deployed to other hosts as needed

## Future Scripts

Ideas for additional scripts:
- `setup-remote-builder.sh` - Configure Nix remote builders
- `backup-system.sh` - Automated backup to HDD/NAS
- `monitor-disk-health.sh` - SMART monitoring for HDDs
- `setup-attic-cache.sh` - Configure Attic binary cache client

## Contributing

When adding new scripts:
1. Include comprehensive comments
2. Add usage examples
3. Make them idempotent (safe to re-run)
4. Add rollback instructions
5. Update this README

## License

Scripts are part of unified-nix-configuration and use the same license.
