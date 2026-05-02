# Adding a New Secret with Agenix

This guide explains how to add a new secret to the repository using agenix encryption.

## Overview

Secrets in this repository are encrypted using `agenix` with age encryption. Each secret is encrypted for specific recipient keys (user keys and/or host keys) defined in `secrets.nix`.

## Prerequisites

- The host(s) that need the secret must have their public keys in `secrets.nix`
- You must have access to one of the operator user keys (defined in `operatorUsers` in `secrets.nix`)
- The repo-standard secret editing command: `agenix-edit`
- Local encryption tools: `age` or `rage`

> Repo policy: prefer `agenix-edit secrets-agenix/<name>.age` over invoking a
> raw `agenix` binary directly. The wrapper is what this repo intentionally
> exposes on operator machines, and it stays compatible with the `secrets.nix`
> recipient model used here.

## Step-by-Step Process

### 1. Define the Secret Recipients in `secrets.nix`

First, determine which hosts and users need access to the secret.

**Example:** For a secret used by the `podman` host service:

```nix
# In secrets.nix, find or create the appropriate recipient list
podmanServiceSecrets = operatorUsers ++ machineRecipients "podman";
```

**Common recipient patterns:**
- `userOnlySecrets` - Only operator users (for personal API keys, etc.)
- `<hostname>ServiceSecrets` - Operators + specific host (for host services)
- `<service>ClientSecrets` - Operators + multiple hosts (for shared client configs)

### 2. Add Secret Entry to `secrets.nix`

Add an entry mapping the secret file to its recipients:

```nix
# In the main secrets block at the bottom of secrets.nix
"secrets-agenix/paperless-db-password.age".publicKeys = podmanServiceSecrets;
```

**Naming convention:** `secrets-agenix/<descriptive-name>.age`

### 3. Create Unencrypted Secret File (Temporary)

Create a temporary unencrypted file with your secret content:

```bash
cd /path/to/unified-nix-configuration
echo 'PAPERLESS_DBPASS="your-secret-here"' > secrets-agenix/paperless-db-password
```

**Important:** This file will be encrypted and then deleted - it should never be committed!

### 4. Encrypt the Secret

Use the repo-standard wrapper to encrypt the secret file based on the
recipients in `secrets.nix`:

```bash
# Method 1: Using pipe (recommended for automation)
cat secrets-agenix/paperless-db-password | \
  EDITOR="tee" agenix-edit secrets-agenix/paperless-db-password.age

# Method 2: Interactive editor (for manual editing)
agenix-edit secrets-agenix/paperless-db-password.age
# This opens your $EDITOR with a temporary decrypted version
# Add your secret content, save, and exit
```

### 5. Verify Encryption

Check that the encrypted file was created correctly:

```bash
ls -lh secrets-agenix/paperless-db-password.age
file secrets-agenix/paperless-db-password.age
# Should show: "age encrypted file, ssh-ed25519 recipient, among others"
```

### 6. Remove Unencrypted File

**Critical security step:** Delete the unencrypted temporary file:

```bash
rm secrets-agenix/paperless-db-password
```

### 7. Configure Secret Usage in Host Config

In the host configuration that needs the secret, add an `age.secrets` entry:

```nix
# Example: hosts/nixos-lxc/podman/default.nix
{
  config,
  pkgs,
  ...
}: {
  age.secrets."paperless-db-password" = {
    file = ../../secrets-agenix/paperless-db-password.age;
    mode = "0400";
    owner = "paperless";  # Optional: set specific owner
    group = "paperless";  # Optional: set specific group
  };

  # Use the secret in your service configuration
  services.paperless = {
    enable = true;
    passwordFile = config.age.secrets."paperless-db-password".path;
  };
}
```

**Key points:**
- The `file` path is relative to the host config file
- The decrypted secret will be available at `config.age.secrets."<name>".path`
- Secrets are decrypted at boot time to `/run/agenix/<name>`
- Default mode is `0400` (read-only by owner)

### 8. Commit and Deploy

```bash
# Add only the encrypted file to git
git add secrets-agenix/paperless-db-password.age
git add secrets.nix
git add hosts/nixos-lxc/podman/default.nix  # Or wherever you configured usage

# Commit (without GPG signing for agents)
git commit --no-gpg-sign -m "feat: add paperless database password secret"

# Push to remote
git push

# Deploy to target host
sudo nixos-rebuild switch --flake .#podman
```

## Common Recipient Configurations

### User-Only Secrets (Personal API Keys)

```nix
# secrets.nix
"secrets-agenix/github-token.age".publicKeys = userOnlySecrets;
```

### Single Host Service Secrets

```nix
# secrets.nix
routerServiceSecrets = operatorUsers ++ machineRecipients "router";
"secrets-agenix/cloudflare-api-key.age".publicKeys = routerServiceSecrets;
```

### Multi-Host Client Secrets

```nix
# secrets.nix
atticClientSecrets = operatorUsers ++ builtins.concatLists (map machineRecipients atticClientHosts);
"secrets-agenix/attic-client-token.age".publicKeys = atticClientSecrets;
```

## Editing Existing Secrets

To edit an already-encrypted secret:

```bash
agenix-edit secrets-agenix/paperless-db-password.age
# Edit in $EDITOR, save, and exit
```

This will re-encrypt the secret with the current recipients from `secrets.nix`.

## Re-keying Secrets

If you add/remove hosts from a recipient list, you must re-encrypt affected secrets:

```bash
# Edit secrets.nix to update recipients
# Then re-encrypt each affected secret
agenix-edit secrets-agenix/affected-secret.age
# Just open and save without changes to re-encrypt with new recipients
```

## Troubleshooting

### "Error: no recipients specified"
- Check that the secret entry exists in `secrets.nix`
- Verify the recipient list includes valid public keys
- Ensure host keys exist in `machineIdentity` or the `hosts` map

### "Error: unable to decrypt"
- You may not have the private key corresponding to any recipient
- Check that your SSH key is in `operatorUsers`
- Verify you're using the correct SSH identity: `ssh-add -l`

### Secret not available at runtime
- Verify `age.secrets."<name>"` is configured in host config
- Check that the secret file path is correct (relative to config file)
- Ensure the host's private key is accessible during boot
- Check system logs: `journalctl -u agenix.service`

## Security Best Practices

1. **Never commit unencrypted secrets** - Always encrypt before committing
2. **Use minimal recipients** - Only grant access to hosts/users that need it
3. **Rotate secrets regularly** - Especially after removing host access
4. **Use strict file permissions** - Default `0400` is usually appropriate
5. **Audit secret access** - Check `secrets.nix` to see who has access to what

## Related Documentation

- [Adding a New Host](./agenix-add-host-guide.md) - How to add host keys for secret encryption
- [Host Migration Checklist](./agenix-host-migration-checklist.md) - Migrating hosts to agenix
- [Machine Identity Inventory](./agenix-machine-identity-inventory.md) - Current host key inventory
