# Improvements (2026-03-27)

This document is the live backlog for `unified-nix-configuration`.  It is
intentionally actionable: each item describes what to do, what the blocker is
(if any), and what success looks like.  Update or replace it as items ship.

## Active threads — do not clobber

- **authentik-host bootstrap** — staged in the working tree (8 files).  Commit
  those files when the host is ready.  Everything else is safe to work on in
  parallel.

---

## Immediately actionable (low risk, no external dependencies)

### A. Add machine-identity keys for inference1/2/3, phoenix, rustdesk

**Why it matters:** `machineRecipients` silently returns `[]` for any host that
has neither a `.pub` file in `ssh-keys/agenix-machine-identities/` nor a
legacy key in the `hosts` dict in `secrets.nix`.  This means those machines
cannot self-decrypt agenix secrets (attic-client-token, root-ssh-key, etc.).
The `inventory-consistency` check now surfaces these as a non-fatal notice.

**What to do:**
1. SSH into each host and read `/etc/ssh/ssh_host_ed25519_key.pub` (or run
   `my.agenix.machineIdentity` bootstrap if that module is active).
2. Write the key to `ssh-keys/agenix-machine-identities/<hostname>.pub`.
3. Run `agenix-edit` on any secret those hosts need to re-key, or run
   `nix run github:ryantm/agenix -- -r` to rekey all.
4. Verify `inventory-consistency` notice disappears.

**Hosts:** inference1, inference2, inference3, phoenix, rustdesk

---

### B. Migrate inference-fresh to den aspect

**Why it matters:** `inference-fresh` is the last non-gateway legacy host.
Migrating it removes it from `legacyHostAllowlist` in `checks.nix` and closes
the mixed-inventory model.

**Blocker:** `inference-vm-base` imports
`hosts/nixos/inference-vm/modules/configuration.nix` which hard-codes NVIDIA
drivers (`services.xserver.videoDrivers = ["nvidia"]`; `hardware.nvidia.*`).
`inference-fresh` was deliberately set up without GPU drivers (all NVIDIA lines
commented out).  Using `inference-vm-base` as-is would add unwanted NVIDIA
config.

**How to unblock — option 1 (preferred):**
Extract the NVIDIA block out of `hosts/nixos/inference-vm/modules/configuration.nix`
into a separate `inference-vm-nvidia.nix` module and exclude it in the base
import list (alongside `gpu-infrastructure.nix`, `ollama.nix`, `llama-cpp.nix`).
Then create:
```nix
# den/hosts/inference-fresh/default.nix  (mirrors inference1 pattern)
den.mkHostModule {
  name = "inference-fresh";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/inference-vm/hosts/inference-fresh/hardware-configuration.nix
    ({ ... }: { networking.hostName = "inference-fresh"; boot.growPartition = true; })
  ];
  aspectsList = [ "inference-vm-base" ];  # no ollama, no nvidia
}
```
Update `den/inventory/hosts.nix` to `mode = "aspect"` and point `hostPath` at
the new den leaf.  Remove `"inference-fresh"` from `legacyHostAllowlist`.

**How to unblock — option 2 (quicker but messier):**
Create an `inference-vm-base-nogpu` aspect that imports only the non-GPU
modules from `inference-vm/modules/`.  Use it for inference-fresh only.

---

### C. Derive Caddy dynamic_dns domain list from lib/hosts.nix

**Why it matters:** `hosts/nixos/gateway/caddy.nix` has a manually maintained
list of DDNS-managed subdomains that must be kept in sync with
`lib/hosts.nix`'s `gateway.services`.  They can drift.

**Current DDNS list (caddy.nix line ~35):**
```
deepwatercreature.com @ homelab authentik paperless 2fauth nightscout marreta linkwarden
```

**Excluded intentionally (with comment):** `home-assistant` — published as a
Cloudflare CNAME to a separate DDNS host.

**Not in DDNS list but in `gateway.services`:** `www`, `dashboard`, `grafana`
(these point at internal IPs, no DDNS needed).

**What to do:**
1. Add an `excludedFromDdns` list to `lib/hosts.nix` (or use a separate
   `ddnsServices` field on the gateway entry).
2. Have `caddy.nix` import `lib/hosts.nix` and derive the domain list from
   `gateway.services` minus `excludedFromDdns`.
3. This makes DDNS alignment automatic when new services are added.

**Risk:** Medium — touching live Caddy config.  Test with `nixos-rebuild test`
before switching.

---

### D. Add per-aspect invariant checks

**Why it matters:** The inventory checks verify structure but not semantics.
Useful invariants that would catch real mistakes:

1. **Every LXC aspect host must include a networking aspect** — currently
   `lxc-core` doesn't imply networking; `lxc-dhcp-networking` must be added
   separately.  A check could assert any host with `lxc-core` also has
   `lxc-dhcp-networking` (or another networking aspect if one is added later).

2. **Every aspect host should have `nixos-base`** — without it the host is
   missing common NixOS settings.  This is already the convention but not
   enforced.

**Where to add:** `outputs/checks.nix` — extend `hostAspectLists` validation.

---

## Needs design work / not immediately safe

### E. Gateway legacy → den migration

**Why it matters:** `gateway` is the most complex host and the last in
`legacyHostAllowlist`.

**Blockers:**
- `dns-zone.nix` and `caddy.nix` are tightly coupled host-local files; no
  obvious aspect boundary yet.
- `nix-router-optimized` input provides specialised modules
  (`router-networking`, `router-firewall`, etc.) that don't map cleanly to a
  simple aspect.
- Migration would need a new `gateway-router` aspect (or several) that wrap the
  nix-router-optimized modules.

**Suggested approach:** Model gateway as a single large `gateway-router` aspect
that imports the nix-router-optimized modules and the local networking/caddy
files, then wraps host-specific configuration in `extraImports`.  Do not
attempt to fully decompose until there are multiple gateway-like hosts.

**Do not rush this** — gateway is a live production router.

---

### F. Authentik → dedicated host completion

The `authentik-host` LXC is being bootstrapped (staged changes).  Once it is
live:

1. Update `caddy.nix` to proxy `authentik.deepwatercreature.com` at the new
   host IP (`10.10.11.70`) instead of `homeserver` (`10.10.11.69:19000`).
2. Move `secrets-agenix/authentik-env.age` recipient from `homeserverServiceSecrets`
   to a new `authentikHostServiceSecrets` group.
3. Remove the Authentik aspect from `den/hosts/homeserver/default.nix` once
   the service is confirmed running on the dedicated host.
4. Update `lib/hosts.nix`: `gateway.services` already has `authentik`; no DNS
   change needed.

---

## Working rules for agents

- Run `nix build .#checks.x86_64-linux.inventory-consistency` after every
  structural change.
- Commit without GPG signing: `git commit --no-gpg-sign`.
- Keep changes build-tested.  Prefer narrow commits by concern.
- Do not modify staged `authentik-host` files unless continuing that thread.
- Do not rekey secrets casually — recipients must be correct before rekeying.
