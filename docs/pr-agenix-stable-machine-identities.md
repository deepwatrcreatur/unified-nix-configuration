# PR: Introduce Stable Agenix Machine Identities

## Summary

This PR starts migrating machine-scoped agenix secrets away from SSH host keys.

It adds:

- a dedicated machine identity module for agenix
- a stable public-key directory at `ssh-keys/agenix-machine-identities/`
- recipient selection in `secrets.nix` that prefers stable machine identities and falls back to legacy host SSH keys
- inventory files for Dashlane and rollout tracking

## Why

Using `/etc/ssh/ssh_host_ed25519_key` as the agenix identity couples secret
decryption to host reprovisioning. If a host is rebuilt and its SSH host key
changes, agenix recipients drift and machine decryption breaks.

The new structure decouples machine secret decryption from host SSH key churn.

## Migration Notes

- No host is forced onto the new identity path yet.
- Existing recipients still work because `secrets.nix` falls back to host SSH keys.
- Once a host has `/var/lib/agenix/machine-identity` provisioned and its public key
  committed to `ssh-keys/agenix-machine-identities/{hostname}.pub`, secrets can be
  rekeyed without depending on the SSH host key.

## Validation

- `nix flake check` loads the new module files and then fails in an unrelated
  existing evaluation path with `The option 'host.type' was accessed but has no value defined.`
