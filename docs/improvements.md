# Improvements (updated 2026-03-28)

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
   the `my.agenix.machineIdentity` bootstrap if that module is active).
2. Write the key to `ssh-keys/agenix-machine-identities/<hostname>.pub`.
3. Run `nix run github:ryantm/agenix -- -r` to rekey all secrets.
4. Verify `inventory-consistency` notice disappears.

**Hosts:** inference1, inference2, inference3, phoenix, rustdesk

---

### C. Derive Caddy dynamic_dns domain list from lib/hosts.nix

**Why it matters:** `hosts/nixos/router/caddy.nix` has a manually maintained
list of DDNS-managed subdomains that must be kept in sync with
`lib/hosts.nix`'s `router.services`.  They can drift.

**Current DDNS list (caddy.nix ~line 35):**
```
deepwatercreature.com @ homelab authentik paperless 2fauth nightscout marreta linkwarden
```

**Excluded intentionally:** `home-assistant` — published as a Cloudflare CNAME
to a separate DDNS host.

**Not in DDNS list but in `router.services`:** `www`, `dashboard`, `grafana`
(point at internal IPs, no DDNS needed).

**What to do:**
1. Add a `ddnsServices` field to the router entry in `lib/hosts.nix`.
2. Have `caddy.nix` import `lib/hosts.nix` and derive the domain list from it.
3. Makes DDNS alignment automatic when new services are added.

**Risk:** Medium — touching live Caddy config.  Test with `nixos-rebuild test`
before switching.

---

### G. Wire NTP DHCP option 42 through Technitium

**Why it matters:** The router now runs chrony (10.10.10.1) but clients only
discover it automatically if DHCP option 42 advertises it.

**What to do:**
1. In `nix-router-optimized`, add `ntpServers` option to the Technitium
   provider path of `router-dns-service` to set DHCP scope option 42 via API.
2. In this repo: `services.router-dns-service.ntpServers = ["10.10.10.1"]`
   in `hosts/nixos/router/networking.nix`.

**Short-term:** Configure option 42 in Technitium web UI manually while the
nix-router-optimized feature is developed.

---

## Needs design work / not immediately safe

### D. Add per-aspect invariant checks (partial)

**Status:** LXC networking check is live in `outputs/checks.nix`.

**Remaining:** Assert every non-LXC aspect host includes `nixos-base`.
Currently convention but not enforced.

---

## Working rules for agents

- Run `nix build .#checks.x86_64-linux.inventory-consistency` after every
  structural change.
- Commit without GPG signing: `git commit --no-gpg-sign`.
- Keep changes build-tested.  Prefer narrow commits by concern.
- Do not modify staged `authentik-host` files unless continuing that thread.
- Do not rekey secrets casually — recipients must be correct before rekeying.
