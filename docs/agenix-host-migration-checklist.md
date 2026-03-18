# Agenix Host Migration Checklist

Use this checklist to migrate each host from SSH-host-key-based agenix
decryption to a stable dedicated machine identity.

This is the operational runbook version of the broader guide in
`docs/agenix-add-host-guide.md`.

## Goal

For each host:

1. Generate a stable private machine identity on the host
2. Commit the matching public key to the repo
3. Store recovery material in Dashlane
4. Enable the stable agenix machine identity module for that host
5. Rekey secrets
6. Rebuild and verify decryption

## Preconditions

- The repo is up to date on the admin machine
- The target host is reachable
- You have root access on the target host
- GitHub SSH access works for any private `git+ssh` flake inputs used by that host

## Per-Host Steps

### 1. Pull the latest repo state

On the admin machine:

```bash
cd /home/deepwatrcreatur/flakes/unified-nix-configuration
git pull
```

### 2. Generate the stable machine identity on the host

Run on the target host as `root`:

```bash
install -d -m 700 /var/lib/agenix
ssh-keygen -t ed25519 -N '' -C "agenix-machine-identity $(hostname)" -f /var/lib/agenix/machine-identity
chmod 400 /var/lib/agenix/machine-identity
```

This creates:

- private key: `/var/lib/agenix/machine-identity`
- public key: `/var/lib/agenix/machine-identity.pub`

### 3. Copy the public key into the repo

From the admin machine:

```bash
ssh HOSTNAME 'cat /var/lib/agenix/machine-identity.pub' > ssh-keys/agenix-machine-identities/HOSTNAME.pub
```

Do not commit the private key.

### 4. Record the host in Dashlane

Use the naming convention from:

- `docs/agenix-machine-identity-dashlane.txt`
- `docs/agenix-machine-identity-inventory.md`

Store:

- host name
- private key recovery material
- runtime path: `/var/lib/agenix/machine-identity`
- public key text

### 5. Enable the stable machine identity module for the host

In the host's NixOS configuration, ensure:

```nix
{
  my.agenix.machineIdentity.enable = true;
}
```

Leave legacy fallback enabled during migration unless you have already verified
the host decrypts successfully with the stable identity alone.

Default behavior:

- stable identity path: `/var/lib/agenix/machine-identity`
- fallback identity: `/etc/ssh/ssh_host_ed25519_key`

### 6. Ensure the host is in the right recipient groups

Check `secrets.nix` and make sure the host is included anywhere it needs
machine-scoped secret access.

Common cases:

- remote builder client: `remoteBuilder.supportedHosts`
- attic client: `atticClientHosts`
- service-specific secret groups

### 7. Rekey agenix secrets

From the repo root:

```bash
agenix -r
```

This updates recipients using the stable machine public key when present.

Before doing this, verify that `agenix` is the `ryantm/agenix` tool expected by
this repo.

On `workstation`, the default `agenix` in `PATH` was actually `agenix-cli`,
which expects `.agenix.toml` and is incompatible with this repo's
`secrets.nix`-based workflow.

If `agenix --help` output or runtime errors mention `.agenix.toml` or
`Failed to find config root`, do not use that binary for rekeying.

### 8. Commit and push the public key plus recipient changes

Example:

```bash
git add ssh-keys/agenix-machine-identities/HOSTNAME.pub secrets.nix
git commit -m "Add stable agenix machine identity for HOSTNAME"
git push
```

If `agenix -r` changed encrypted files, include those too.

### 9. Rebuild the host

Run the appropriate rebuild command for that host.

Example for NixOS:

```bash
sudo nixos-rebuild switch --flake .#HOSTNAME
```

If the rebuild fails fetching a private `git+ssh` flake input, verify:

```bash
ssh -T git@github.com
```

If user SSH works but `nix-daemon` cannot fetch private flake inputs, temporarily
bridge the SSH agent socket for the current boot:

```bash
sudo systemctl set-environment SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh
sudo systemctl restart nix-daemon
```

Then retry the rebuild.

### 10. Verify decryption on the host

Run on the target host:

```bash
test -f /var/lib/agenix/machine-identity
sudo systemctl status agenix.service --no-pager
sudo ls -l /run/agenix
```

Verify that expected secrets are present and owned correctly.

### 11. Keep fallback until the host is proven stable

Do not remove SSH-host-key fallback immediately.

Only remove fallback after:

- the host rebuilds successfully
- agenix decrypts successfully
- the host continues working after reboot

## Suggested Rollout Order

1. Workstation
2. Gateway
3. Attic-cache
4. Homeserver
5. Remaining Proxmox hosts

Start with lower-risk hosts and only remove fallback after confidence is high.

## Troubleshooting

### Rebuild fails fetching private flake inputs

Symptom:

- `Permission denied (publickey)` while fetching `git+ssh://...`

Checks:

```bash
ssh -T git@github.com
sudo SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh git ls-remote ssh://git@github.com/OWNER/REPO
```

If manual SSH works but the rebuild does not, the issue is usually `nix-daemon`
not seeing the user's SSH agent socket.

### Agenix still decrypts via host SSH key

That is expected during migration if fallback is still enabled.

Stable keys are preferred when the matching public key exists in:

`ssh-keys/agenix-machine-identities/HOSTNAME.pub`

### Host rebuilt or reprovisioned

If the host keeps the same `/var/lib/agenix/machine-identity`, secrets should
continue to decrypt without rekeying.

That is the main reason for this migration.

### `agenix -r` fails with `.agenix.toml` or `config root` errors

Symptom:

- `Failed to find config root`
- `Failed to find .agenix.toml`

Meaning:

- you are using the wrong `agenix` binary
- the host package is likely `agenix-cli`, not `ryantm/agenix`

Action:

- stop using the host's default `agenix` command for rekeying
- use the `ryantm/agenix` tool that matches this repo's `secrets.nix` workflow
- do not assume package name alone is sufficient; verify behavior before rekeying
