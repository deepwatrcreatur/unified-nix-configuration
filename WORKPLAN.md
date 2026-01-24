# Workplan: Improve nix-attic-infra

## Context
Refactoring `unified-nix-configuration` to use upstream `inputs.nix-attic-infra.nixosModules.attic-client` and `.attic-post-build-hook` instead of local `myModules.attic-client`. The upstream modules need security hardening that was just applied to our local module.

## Improvements to Apply

### 1. Security hardening in `modules/nixos/attic-client.nix`

**Current issues in upstream:**
- SOPS secret for `attic-client-token` doesn't set `mode = "0400"` (world-readable by default)
- `/run/nix/attic-token-bearer` written with `chmod 0644` (world-readable)
- Missing readability checks before reading token file (can mask permission errors)

**Apply the following (matching what we did in unified-nix-configuration):**

#### a) SOPS secret permissions
In `modules/nixos/attic-client.nix`, in the `sops.secrets."attic-client-token"` block:
```nix
mode = "0400";  # restrict to owner-only read
```

#### b) Token bearer file permissions
In the `nix-attic-token.service` script, replace:
```nix
chmod 0644 /run/nix/attic-token-bearer
```
with:
```nix
umask 0077
echo "bearer $token" > /run/nix/attic-token-bearer
chmod 0600 /run/nix/attic-token-bearer
```

#### c) Add readability checks
Before reading token in both post-build hook and token preparation service, add:
```bash
if [ ! -r "$token_file" ]; then
  echo "Attic: Token file not readable, skipping push" >&2
  exit 0
fi
```

### 2. Update documentation
- Document that these security features are applied
- Update `ARCHITECTURE.md` or `README.md` with security notes

## Files to Edit

1. `~/flakes/nix-attic-infra/modules/nixos/attic-client.nix`
   - Line ~53-59: Add `mode = "0400"` to SOPS secret
   - Line ~137-139: Change `chmod 0644` to `0600` and add `umask 0077`
   - Line ~78-81: Add readability check in post-build hook
   - Line ~134-136: Add readability check in token preparation service

## Testing

- After applying changes, rebuild a test host and verify:
  - SOPS secret is mode 0400
  - `/run/nix/attic-token-bearer` is mode 0600 (not 0644)
  - Token provisioning works correctly
  - Post-build hook logs readability errors appropriately

## Notes

- This workplan is created because unified-nix-configuration is in `/home/deepwatrcreatur/flakes/unified-nix-configuration`
- Agent is currently in that directory; to work on `~/flakes/nix-attic-infra`, restart agent from that directory
- A small PR was merged between feature branch and main on GitHub, ensure you're on latest `main` when starting
