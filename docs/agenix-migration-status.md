# Agenix Migration Status

**Last updated:** 2026-03-11 01:17 UTC

## Current State: ✅ Phase 2 - Parallel Operation

Both sops-nix and agenix are running simultaneously on workstation for testing.

## Completed

### Infrastructure
- ✅ Added agenix to flake inputs
- ✅ Collected host SSH keys (gateway, workstation, attic-cache)
- ✅ Auto-generated `secrets.nix` from ssh-keys directory
- ✅ Created migration scripts (`collect-host-keys.sh`, `generate-secrets-nix.sh`)

### Workstation (Test Host)
- ✅ Agenix module imported
- ✅ Migrated secrets:
  - `github-token` → `/run/agenix/github-token-agenix`
  - `grok-api-key` → `/run/agenix/grok-api-key`
  - `openrouter-api-key` → `/run/agenix/openrouter-api-key`
  - `z-ai-api-key` → `/run/agenix/z-ai-api-key`
  - `opencode-zen-api-key` → `/run/agenix/opencode-zen-api-key`
- ✅ All secrets decrypt successfully
- ✅ Owned by `deepwatrcreatur:users` with correct permissions

## Testing Needed

1. **Verify fnox integration** - Update fnox to read from agenix paths
2. **Test API key usage** - Ensure apps can read from `/run/agenix/`
3. **Compare sops vs agenix** - Verify both produce same values

## Remaining Secrets to Migrate

### User Secrets (users/deepwatrcreatur/secrets/)
- `atuin-key-b64.txt.enc` - Shell history sync
- `oauth_creds.json.enc` - Gemini OAuth (binary)
- `bitwarden_data_json` - Bitwarden data (binary)
- `gpg-private-key.asc.enc` - GPG key (large binary)
- `rclone.conf.enc` - Rclone config (binary)
- `attic-client-token.yaml.enc` - Already configured separately

### System Secrets
- Cloudflare API keys (homeserver, gateway)
- Technitium API key (gateway, workstation)
- InfluxDB passwords (homeserver)
- Kasa collector tokens (homeserver)

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
