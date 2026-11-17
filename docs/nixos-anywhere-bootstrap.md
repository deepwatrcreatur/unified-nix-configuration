# NixOS Anywhere Bootstrap Guide

This guide covers bootstrapping a new NixOS host from this repo using
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere). The justfile
recipes in the repo root automate the workflow.

## Why this approach

agenix decrypts secrets at boot using the host's private key. If the key is not
known to `secrets.nix` at install time, agenix fails on first boot and a second
rebuild pass is required. By pre-generating the machine identity, adding it to
`secrets.nix`, rekeying, and seeding the key into the installed system via
`--extra-files`, agenix works correctly **on first boot** with no second pass.

## Prerequisites

- nixos-anywhere is invoked via `nix run` — no separate install needed
- Target machine is booted from the NixOS installer ISO and reachable via SSH
- The host's NixOS config exists in this repo with `my.agenix.machineIdentity.enable = true`
- For Btrfs/disko hosts: UEFI firmware, disk device path known

## Step-by-step workflow

### 1. Generate the machine identity

```bash
just gen-identity <host>
```

This creates a stable ed25519 key pair and:
- Saves the **public key** to `ssh-keys/agenix-machine-identities/<host>.pub`
- Holds the **private key** at `/tmp/nix-bootstrap-<host>/machine-identity` (mode 400, dir mode 700) until `just install` consumes and removes it

If a public key already exists for the host, the command is a no-op.

### 2. Add the host to `secrets.nix`

Open `secrets.nix` and add `<host>` to the appropriate recipient groups. The
`machineRecipients` helper in `lib/agenix-machine-identities.nix` will
automatically pick up the new `.pub` file by hostname.

Common groups to consider:

| Group | What it grants |
|---|---|
| `rootSshKeyHosts` | Auto-deploys the root SSH identity to the host |
| `atticClientHosts` | Gives the host the attic cache token |
| Host-specific groups | Service secrets scoped to this host |

### 3. Rekey secrets

```bash
just rekey
```

Re-encrypts all `secrets-agenix/*.age` files to include the new host as a
recipient. This must be done before install — the encrypted secrets are baked
into the Nix store derivation that nixos-anywhere will deploy.

### 4. Install

```bash
just install <host> <target-ip>
```

Runs `nix run github:nix-community/nixos-anywhere` with:
- `--extra-files` seeding the machine identity to `/var/lib/agenix/machine-identity`
  on the installed system
- `--flake .#<host>`
- `--ssh-option StrictHostKeyChecking=accept-new`

The private key is **deleted from `/tmp`** automatically on success. If install
is interrupted, run `just clean-identity <host>` to remove it manually.

#### Optional parameters

`just` passes recipe arguments **by position**, in this order:
`just install <host> <target> [hw] [disk] [accept_new] [dir]`. Pass `""` to
skip one. `name=value` does not work: `just install h 1.2.3.4 accept_new=true`
sets `hw` to the string `accept_new=true` and the recipe stops with
"hw path not found".

| Position | Parameter | Purpose | Example |
|---|---|---|---|
| 3 | `hw` | Auto-generate `hardware-configuration.nix` via `nixos-generate-config` | `hosts/nixos/myhost/hardware-configuration.nix` |
| 4 | `disk` | disko disk device (label is always `main`) | `/dev/disk/by-id/scsi-0QEMU_...` |
| 5 | `accept_new` | `true` for trust-on-first-use SSH host key verification (see note below) | `true` |
| 6 | `dir` | Path to this repo (defaults to `$PWD`) | `/home/user/flakes/unified-nix-configuration` |

> **SSH host key verification**: by default `just install` uses strict host key
> checking. Since the installer generates a fresh host key you haven't seen
> before, you have two options:
> - Pre-verify: `ssh-keyscan <target> >> ~/.ssh/known_hosts` before running install
> - TOFU opt-in: pass `true` as the fifth argument; convenient but skips verification

Full example for an inference VM:

```bash
just install inference4 10.10.11.134 \
    hosts/nixos/inference-vm/hosts/inference4/hardware-configuration.nix \
    /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0 \
    true
```

TOFU only, no hardware generation or disk override:

```bash
SSH_AUTH_SOCK="" just install <host> <target-ip> "" "" true
```

### 5. Commit

After install completes, `just install` prints a `git status` of the files that
changed. Commit them:

```bash
git add ssh-keys/agenix-machine-identities/<host>.pub secrets-agenix/
git commit -m "feat: add <host> machine identity and rekey secrets"
```

### 6. User secrets & Workstation Operator Identity (post-install)

- **Headless & Server Nodes:** System-level secrets (`/run/agenix/`) are fully handled by the steps above via `/var/lib/agenix/machine-identity`.
- **Developer Workstations:** Hosts using `developer.nix` (e.g. `emerald`, `phoenix`, `workstation`) decrypt user secrets into `~/.local/share/agenix-user-secrets/` using the operator's personal SSH key at `~/.ssh/id_ed25519`.

On a fresh workstation install:
1. Seed the operator identity key to `~/.ssh/id_ed25519` (from Dashlane or an existing workstation):
   ```bash
   scp -p user@existing-workstation:~/.ssh/id_ed25519 ~/.ssh/id_ed25519
   chmod 600 ~/.ssh/id_ed25519
   ```
2. Re-run `nh os switch ~/flakes-worktrees/main` to automatically decrypt all developer API keys and user credentials.

For hosts using legacy/Proxmox secrets:
```bash
cd ansible
ansible-playbook playbooks/setup-secrets.yml -l <host>
```

## Quick reference

```bash
just gen-identity <host>          # Step 1: generate identity
# edit secrets.nix
just rekey                         # Step 3: rekey
just install <host> <ip>           # Step 4: install

just clean-identity <host>         # Manual cleanup if install was interrupted
just rekey                         # Re-run any time secrets.nix changes
```

## How it fits with the existing Ansible playbook

`ansible/playbooks/bootstrap-nixos-inference.yml` uses a post-install approach:
it generates the machine identity *after* nixos-anywhere finishes and then
rekeys. This means the first boot has no working agenix secrets and requires a
follow-up `nixos-rebuild switch`. The justfile approach avoids this by
pre-seeding the identity, making it the preferred path for new hosts. The
Ansible playbook remains useful for bulk inference VM deployments via inventory.
