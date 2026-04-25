# 30 Kea DDNS TSIG Key Provisioning

Status: `done`
Suggested branch: `feat/router-kea-tsig-key`
Priority: `high`

## Goal

Generate a TSIG key for Kea D2 ↔ Technitium RFC2136 authentication, store it
as an agenix secret, and wire it into the router host so both Kea and the
Technitium sync service can read it at runtime.

## Why

The TSIG key is the shared secret that lets Kea D2 sign RFC2136 DNS update
requests and lets Technitium verify them. It must be provisioned before the
`router-kea` module (item 31) can be tested end-to-end.

## Validation Findings

Tested manually on 2026-04-18:
- Technitium 14.0 on router accepts RFC2136 updates from 127.0.0.1 ✓
- TSIG HMAC-SHA256 works once the key is registered in Technitium settings ✓
- Technitium TSIG key API: POST `api/settings/set?tsigKeys=name|b64secret|hmac-sha256`
  (sets the global TSIG key list; existing keys are replaced, so always send full list)
- Zone update policy: `api/zones/options/set?zone=…&update=Allow&updateNetworkACL=127.0.0.1`
- `BADKEY` error means the key is not yet registered in Technitium settings (not a
  fundamental incompatibility)

## Scope

- Generate TSIG key: `openssl rand -base64 32`
- Encrypt as `secrets-agenix/kea-ddns-tsig-key.age` with router host key
- Add to `secrets.nix` with router public key
- Expose on router via `age.secrets.kea-ddns-tsig-key`
- Document the path so items 31 and 32 can reference it

## Non-Goals

- Kea itself (item 31)
- Technitium zone reconfiguration (item 32)

## Validation

- `nix eval` on router host confirms secret path resolves
- `agenix-edit --decrypt` confirms secret is readable with router host key

## Dependencies

None — standalone secret provisioning.
