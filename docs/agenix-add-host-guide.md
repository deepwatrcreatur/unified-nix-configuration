# Adding a Host to Stable Agenix Machine Identities

This repo now supports dedicated machine identities for agenix so machine-scoped
secrets do not depend on SSH host key churn.

## Goal

For each host:

1. Generate a dedicated private key on the host at `/var/lib/agenix/machine-identity`
2. Commit the matching public key to `ssh-keys/agenix-machine-identities/{hostname}.pub`
3. Enable the machine identity module on that host
4. Rekey secrets so the host uses the stable machine recipient instead of the legacy SSH host key

## 1. Generate the machine identity on the host

Run on the target host as `root`:

```bash
install -d -m 700 /var/lib/agenix
ssh-keygen -t ed25519 -N '' -C "agenix-machine-identity $(hostname)" -f /var/lib/agenix/machine-identity
chmod 400 /var/lib/agenix/machine-identity
```

This creates:

- private key: `/var/lib/agenix/machine-identity`
- public key: `/var/lib/agenix/machine-identity.pub`

## 2. Copy the public key into the repo

From your workstation:

```bash
ssh HOSTNAME 'cat /var/lib/agenix/machine-identity.pub' > ssh-keys/agenix-machine-identities/HOSTNAME.pub
```

Commit that `.pub` file. Do not commit the private key.

## 3. Add the host to the inventory

Update:

- `docs/agenix-machine-identity-inventory.md`
- `docs/agenix-machine-identity-dashlane.txt`

Store the private key or recovery material in Dashlane under the matching item
name from `docs/agenix-machine-identity-dashlane.txt`.

## 4. Enable the module on the host

In the host’s NixOS config, enable the stable machine identity module:

```nix
{
  my.agenix.machineIdentity.enable = true;
}
```

When this module is enabled, agenix uses `/var/lib/agenix/machine-identity`
directly instead of the SSH host key.

## 5. Ensure recipients include the host

If the host should decrypt machine-scoped secrets, add it to the relevant
recipient group in `secrets.nix`.

Common cases:

- **root SSH identity**: add to `rootSshKeyHosts` (auto-deploys `/root/.ssh/id_ed25519`)
- **remote builder client**: add to `remoteBuilder.supportedHosts`
- **attic client**: add to `atticClientHosts`
- **nix-ci.com cache**: add to `nixCiCacheHosts`
- **service host**: add to the relevant service secret group

`secrets.nix` prefers `ssh-keys/agenix-machine-identities/{hostname}.pub` and
only falls back to the legacy SSH host key if the stable public key is missing.

## 6. Rekey secrets

After the public key is committed, rekey the affected secrets:

```bash
agenix -r
```

This updates recipients based on `secrets.nix`.

### Important CLI compatibility note

Do not assume the `agenix` binary in `PATH` is the correct tool for this repo.

On `workstation`, `/run/current-system/sw/bin/agenix` was actually
`agenix-cli 0.1.2`, which expects `.agenix.toml` and fails with:

```text
Failed to find config root
Failed to find .agenix.toml
```

This repo uses the `ryantm/agenix` workflow with a repo-root `secrets.nix`,
not the `.agenix.toml` workflow.

Before rekeying, verify the tool you are about to run is compatible with the
repo. If the help output or errors mention `.agenix.toml`, stop and switch to
the `ryantm/agenix` tool instead of the host's default `agenix` package.

## 7. Deploy and verify

Deploy the host and verify:

```bash
test -f /var/lib/agenix/machine-identity
sudo systemctl status agenix.service --no-pager
sudo ls -l /run/agenix
```

If the host decrypts successfully with the stable key, you can eventually stop
including the legacy host SSH key as a recipient for that host’s secrets.

## Stable User Identities

This repo uses stable SSH identities for users (not per-host keys):

### Root identity (auto-deployed)

The root SSH key is stored in `secrets-agenix/root-ssh-key.age` and auto-deploys
to `/root/.ssh/id_ed25519` on all hosts in `rootSshKeyHosts`.

- **Public key**: `ssh-keys/root-stable-identity.pub`
- **Dashlane**: "ssh stable identity - root"

After adding a host to `rootSshKeyHosts` and rekeying, root automatically gets
the key on next rebuild.

### User identity (manually deployed)

The `deepwatrcreatur` user has a single stable key across all hosts:

- **Public key**: `ssh-keys/deepwatrcreatur-stable-identity.pub`
- **Dashlane**: "ssh stable identity - deepwatrcreatur"

Deploy manually to new hosts:
```bash
scp ~/.ssh/id_ed25519 newhost:~/.ssh/
scp ~/.ssh/id_ed25519.pub newhost:~/.ssh/
ssh newhost "chmod 600 ~/.ssh/id_ed25519"
```

### VM Creation

When creating VMs (Proxmox, cloud), provide both public keys for immediate access:
- Root: contents of `ssh-keys/root-stable-identity.pub`
- User: contents of `ssh-keys/deepwatrcreatur-stable-identity.pub`

## Notes

- Agenix was not a mistake here. It still gives you a cleaner bootstrap path than
  shared `sops-nix` age keys, especially for machine-scoped secrets at boot.
- The problem was not agenix itself; it was tying agenix identities to SSH host keys,
  which are operationally less stable than dedicated machine identities.
