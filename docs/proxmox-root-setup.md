# Proxmox Root Setup

The full operational runbook lives in the `proxmox-host-configuration` repo:
`/home/deepwatrcreatur/flakes/proxmox-host-configuration/docs/proxmox-root-setup.md`

`unified-nix-configuration` owns the `proxmox-root` Home Manager output and the ansible playbooks that deploy it. Below are lessons learned bootstrapping new hosts that apply specifically to this repo.

---

## Bootstrapping a New Proxmox Host

### 1. Register the host in this repo first

Before running any playbooks, the host must be a registered agenix recipient or secrets decryption will fail.

```bash
# Get the SSH host key
ssh-keyscan -t ed25519 <host-ip> | awk '{print $2, $3, "agenix-machine-identity <hostname>"}'

# Add to ssh-keys/agenix-machine-identities/<hostname>.pub
# Add to lib/hosts.nix (ip, sshUser = "root", description)
# Add to ansible/inventory/hosts.yml under proxmox group
# Add "<hostname>" to atticClientHosts in secrets.nix
# Add "<hostname>" to nonNixosHosts in lib/remote-builder.nix

# Rekey all secrets
export RULES=./secrets.nix
nix run github:ryantm/agenix -- -r

# Commit and push
git add -A && git commit -m "Add <hostname> to inventory and secrets"
git push
```

### 2. Bootstrap the host

SSH in as root and run:

```bash
# Optional: Speed up bootstrap by pre-resolving the local cache
echo "10.10.11.39 attic-cache" >> /etc/hosts

# Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

# If no internet (gateway down): route through workstation temporarily
#   On workstation: sudo iptables -t nat -A POSTROUTING -s <host-ip>/32 -j MASQUERADE
#   On host: ip route replace default via <workstation-ip>
#   Revert after: on host: ip route replace default via <gateway-ip>

apt-get install -y git
mkdir -p /root/flakes
git clone https://github.com/deepwatrcreatur/unified-nix-configuration /root/flakes/unified-nix-configuration

# Install home-manager
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run home-manager/master -- init --switch

# Set up machine identity for agenix decryption
mkdir -p /var/lib/agenix
cp /etc/ssh/ssh_host_ed25519_key /var/lib/agenix/machine-identity
chmod 600 /var/lib/agenix/machine-identity
```

### 3. Run the ansible playbooks from the control machine

```bash
cd ansible/

# Decrypt secrets (uses machine identity key on proxmox hosts)
ansible-playbook -i inventory/hosts.yml playbooks/setup-secrets.yml --limit <hostname>

# Apply home-manager config (bootstraps nix.conf caches automatically)
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml --limit <hostname>
```

---

## Key Lessons Learned

### Agenix identity key vs SOPS age key

Secrets in this repo are encrypted to SSH keys via agenix, **not** to SOPS age keys. The `setup-secrets.yml` playbook uses `/var/lib/agenix/machine-identity` (the SSH host key) for proxmox hosts. This is why:

- A new host must be added to `secrets.nix` recipients and secrets rekeyed **before** `setup-secrets.yml` will work
- Copying `~/.config/sops/age/keys.txt` from another machine will not decrypt most secrets

### The `creates:` trap

Using `args: creates:` in Ansible shell tasks means the task is skipped if the output file already exists — even if that file is **empty** from a previously failed run. This left all secret files at 0 bytes silently. The fix (now in the playbook) is to check both existence and `size > 0` before skipping.

### First home-manager run is slow without caches

On a fresh host, `home-manager switch` builds ~170 derivations locally because no substituters are configured yet (home-manager manages nix.conf, but it hasn't run yet — chicken-and-egg). The `update-proxmox.yml` playbook now writes a bootstrap `/etc/nix/nix.conf` with the homelab substituters before running home-manager, so the first run fetches from cache instead of building locally.

### Nix daemon restart after nix.conf changes

If you manually edit `/etc/nix/nix.conf`, restart the daemon: `systemctl restart nix-daemon`

### `age` profile conflict with home-manager-path

During bootstrap, `age` is typically installed standalone via `nix profile install nixpkgs#age` (needed to run agenix decrypt before home-manager is set up). The `home-manager-path` that home-manager installs also provides `age`, causing a profile conflict:

```
error: An existing package already provides the following file:
         /nix/store/.../age-X.Y.Z/share/man/man1/age-inspect.1.gz
```

Fix: `nix profile remove age` before running `home-manager switch`. The `update-proxmox.yml` playbook now handles this automatically.

### Repo on feature branch breaks `git pull --ff-only origin main`

When bootstrapping with a feature branch checked out (e.g. the previous agent cloned and checked out `feat/router-bootstrap-output`), the git pull step fails with "Not possible to fast-forward". If the branch already has all the commits you need, skip the pull:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/update-proxmox.yml --limit <hostname> -e skip_git_pull=true
```

### Pre-existing dotfiles block first home-manager activation

A fresh Proxmox root user has `/root/.bashrc`, `/root/.profile`, and `/root/.ssh/config` from Debian's skeleton. home-manager refuses to overwrite them. The `update-proxmox.yml` playbook passes `-b backup` to move them aside automatically (renamed to `.bashrc.backup`, etc.).
