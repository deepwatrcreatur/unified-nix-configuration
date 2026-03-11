# Agenix Migration Status

**Last updated:** 2026-03-11 05:28 UTC

## Current State: ✅ Phase 2+ - Expanding to Multiple Hosts

Agenix successfully deployed to workstation and gateway. Core secrets migrated.

## Completed

### Infrastructure
- ✅ Added agenix to flake inputs
- ✅ Collected host SSH keys (gateway, workstation, attic-cache, pve-gateway, pve-lattitude, pve-strix, pve-tomahawk)
- ✅ Auto-generated `secrets.nix` from ssh-keys directory
- ✅ Created migration scripts (`collect-host-keys.sh`, `generate-secrets-nix.sh`)

### Workstation (Test Host)
- ✅ Agenix module imported
- ✅ Migrated secrets (9 total):
  - `github-token` → `/run/agenix/github-token-agenix`
  - `grok-api-key` → `/run/agenix/grok-api-key`
  - `openrouter-api-key` → `/run/agenix/openrouter-api-key`
  - `z-ai-api-key` → `/run/agenix/z-ai-api-key`
  - `opencode-zen-api-key` → `/run/agenix/opencode-zen-api-key`
  - `atuin-key-b64` → `/run/agenix/atuin-key-b64`
  - `oauth-creds` (JSON) → `/run/agenix/oauth-creds`
  - `bitwarden-data` (JSON) → `/run/agenix/bitwarden-data`
  - `rclone-conf` → `/run/agenix/rclone-conf`
- ✅ All secrets decrypt successfully (including binary formats)
- ✅ Owned by `deepwatrcreatur:users` with correct permissions
- ✅ Fnox updated to prefer agenix paths

### Gateway
- ✅ Agenix module imported
- ✅ Migrated secrets (1 total):
  - `technitium-api-key` → `/run/agenix/technitium-api-key`
- ✅ DNS sync script tested and working with agenix
- ✅ Deployed successfully

### Attic-Cache
- ✅ Agenix module imported
- ✅ Migrated secrets (1 total):
  - `attic-client-token` → `/run/agenix/attic-client-token`
- ✅ Backward compatibility symlink at `/run/secrets/attic-client-token`
- ✅ Deployed successfully

## Testing Needed

1. ✅ **Verify fnox integration** - Updated to prefer agenix over sops
2. ✅ **Test API key usage** - All secrets accessible at `/run/agenix/`
3. ✅ **Compare values** - Confirmed matching between sops and agenix
4. **Test actual app usage** - Run opencode, gh commands with agenix secrets

## Remaining Secrets to Migrate

### User Secrets (users/deepwatrcreatur/secrets/)
- `gpg-private-key.asc.enc` - GPG key (large binary - optional)

### System Secrets (secrets/)
- `attic-server-private-key.yaml.enc` - Attic server key (when attic server is set up)
- `attic-server-token.yaml.enc` - Attic server token (when attic server is set up)

## Next Actions

1. ✅ **Update fnox config** to support agenix paths alongside sops
2. **Test applications** using migrated secrets
3. **Migrate remaining workstation secrets**
4. **Deploy to gateway** (low-risk, only technitium API key)
5. **Deploy to homeserver** (higher-risk, many services)

## Rollback Plan

If issues arise:
- Remove agenix module import
- Secrets automatically fall back to sops
- Both systems work independently
