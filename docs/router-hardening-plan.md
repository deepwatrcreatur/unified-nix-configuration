# Router Hardening Plan

This document is for follow-up work after `router` is back in a known-good state:

- boots reliably
- routes traffic again
- management IP is reachable
- `router-backup` remains consistent with the same production router role

It is intentionally scoped for parallel agent work on separate branches.

## Current Recovery Context

Recent failure behavior showed:

- `LAN` never got `10.10.10.1`
- `WAN` still acquired DHCP
- monitoring services waited on `10.10.10.1` and cascaded into repeated failures
- recovery was made harder by weak out-of-band behavior

The key lesson is not that LAN should become optional. The lesson is:

- `management` must stay available even when `LAN` or `WAN` is broken
- interface identity and service dependency handling need to be more robust

## Borrowed Ideas Worth Stealing

The best ideas to borrow from router-focused Nix work, especially `chayleaf/nixos-router`, are:

1. Stable interface matching.
   Match by stable device properties instead of trusting kernel-assigned names.

2. Per-interface dependent services.
   Services should depend on the interface they actually need, not on a generic host-wide assumption.

3. Degraded operation model.
   `management` should remain usable even if `LAN` or `WAN` is down.

4. More explicit router-role boundaries.
   Router networking/firewall/monitoring dependencies should be modeled as router concerns, not incidental host behavior.

## What Not To Do

- Do not fork and replace the repo with `chayleaf/nixos-router`.
- Do not make the router silently "healthy" without LAN.
- Do not make management depend on LAN or WAN success.
- Do not make monitoring services block boot in ways that hide the real failure.

## Target End State

After the hardening work:

- `management` comes up independently and early
- `LAN` and `WAN` can fail independently without losing recovery access
- router health is explicit:
  - management up
  - LAN missing
  - WAN missing
- interface identity is stable across VM/hardware churn
- monitoring/dashboard degrade cleanly instead of hanging on missing LAN IP

## Recommended Branches

These are intended as separate PRs.

### 1. `refactor/router-stable-interface-matching`

Goal:
- stop relying on fragile interface names for `router` and `router-backup`

Tasks:
- inspect the current `nix-router-optimized` router-networking options and determine the cleanest stable match path
- if possible, add support for matching by MAC, PCI path, or systemd `.link` match config
- update `router` and `router-backup` to use stable matching for:
  - LAN
  - WAN
  - management
- document the expected mapping in repo docs

Success criteria:
- interface assignment does not depend on `ens*` vs `enp*` naming drift

### 2. `refactor/router-service-dependencies`

Goal:
- stop using broad "wait for `10.10.10.1`" behavior where interface-specific dependencies are more correct

Tasks:
- audit services that currently wait on the LAN IP:
  - Prometheus
  - Grafana
  - Netdata
  - router-dashboard
  - any other router-side services with pre-start polling
- replace IP polling with clearer dependency logic where possible
- keep true LAN-dependent services LAN-aware
- keep management-plane services runnable without LAN

Success criteria:
- broken LAN does not make observability and management look uniformly dead

### 3. `feat/router-management-plane-independence`

Goal:
- make management availability a first-class invariant

Tasks:
- ensure management IP setup is independent from LAN/WAN success
- ensure SSH and dashboard bind in a way that still works on management when LAN fails
- ensure router dashboard links and health checks reflect management-first recovery
- verify `router` and `router-backup` both preserve their distinct management IPs

Success criteria:
- if LAN breaks, `192.168.100.100` and `192.168.100.99` still remain useful for recovery

### 4. `feat/router-health-model`

Goal:
- represent router health explicitly instead of inferring it from individual service failures

Tasks:
- add explicit health checks for:
  - management address present
  - LAN address present
  - WAN address present or WAN link state known
- surface these in the dashboard
- distinguish:
  - healthy
  - degraded: LAN missing
  - degraded: WAN missing
  - degraded: management missing

Success criteria:
- operator can immediately see the real failure domain

### 5. `refactor/router-boot-recovery`

Goal:
- make VM recovery paths reliable and permanent

Tasks:
- verify and keep:
  - Proxmox serial console
  - guest serial console config
  - qemu guest agent
- document exact recovery workflow from Proxmox host
- consider a check or doc to verify the active bootloader entry contains expected kernel args

Success criteria:
- future router lockouts are diagnosable without guesswork

## Ordering

Recommended order after router recovery:

1. `refactor/router-stable-interface-matching`
2. `feat/router-management-plane-independence`
3. `refactor/router-service-dependencies`
4. `feat/router-health-model`
5. `refactor/router-boot-recovery`

## Preconditions

Other agents should not start these branches until:

- `router` is booting the intended generation
- `router` is routing again
- management IP is reachable
- current router and router-backup configs are pulled and switchable

## Notes For Agents

- Keep changes PR-sized and narrowly scoped.
- Do not mix recovery work with refactor work.
- Preserve the current router/spare model:
  - shared production identity
  - distinct management identities
- Prefer explicit invariants and checks over hidden convenience behavior.

## Future Networking Capabilities

These are not part of immediate router recovery. They are worth tracking for
later work once `router` is stable again.

### High Value For This Repo

- `vlan`
  Add first-class VLAN modeling if you want segmented LANs, guest networks, or
  separate management/storage domains.

- `bridge`
  Useful if the router needs to bridge virtual or physical interfaces in a more
  explicit way than today, especially for VM/lab scenarios.

- `bonding`
  Worth considering if future router hardware or hypervisor topology uses
  multiple uplinks and you want link redundancy or throughput aggregation.

### Situational / Lower Priority

- `macvlan`
  Potentially useful for service-isolation edge cases, but not an obvious
  router requirement for the current design.

- `notnft`
  Only worth tracking if there is a real need to support a non-`nftables`
  firewall path. Current router direction should stay nftables-first unless a
  concrete requirement appears.

### Probably Not Worth Prioritizing Now

- `6-to-4`
  Add only if you actually intend to do tunnel-based IPv6 transition work.
  It does not look like a near-term need for the current homelab.

## Post-Recovery Branch Ideas

If the above become relevant after router recovery, treat them as separate,
opt-in work streams rather than part of baseline hardening:

- `feat/router-vlans`
- `feat/router-bridging`
- `feat/router-bonding`
- `feat/router-macvlan`
- `feat/router-non-nft-firewall` only if a real use case emerges
