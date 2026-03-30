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

| Parameter | Purpose | Example |
|---|---|---|
| `hw=` | Auto-generate `hardware-configuration.nix` via `nixos-generate-config` | `hw=hosts/nixos/myhost/hardware-configuration.nix` |
| `disk=` | disko disk device (label is always `main`) | `disk=/dev/disk/by-id/scsi-0QEMU_...` |
| `dir=` | Path to this repo (defaults to `$PWD`) | `dir=/home/user/flakes/unified-nix-configuration` |

Full example for an inference VM:

```bash
just install inference4 10.10.11.134 \
    hw=hosts/nixos/inference-vm/hosts/inference4/hardware-configuration.nix \
    disk=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0
```

### 5. Commit

After install completes, `just install` prints a `git status` of the files that
changed. Commit them:

```bash
git add ssh-keys/agenix-machine-identities/<host>.pub secrets-agenix/
git commit -m "feat: add <host> machine identity and rekey secrets"
```

### 6. User secrets (post-install)

System-level secrets (`/run/agenix/`) are handled by the steps above. User
secrets (`~/.config/sops/`, fnox store) are a separate layer deployed by
Ansible:

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
