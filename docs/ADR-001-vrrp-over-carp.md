# ADR-001: VRRP (keepalived) over CARP for Gateway High Availability

**Date:** 2026-04-25
**Status:** Accepted
**Authors:** Calder

---

## Context

The router pair (`router` + `router-backup`) needs a virtual IP (VIP) that
floats between them so LAN clients always reach the gateway at `10.10.10.1`
regardless of which physical node is active.

OPNsense — a common reference point for homelab HA router design — uses CARP
(Common Address Redundancy Protocol) for this. The question is whether to
follow that pattern or use an alternative.

---

## Decision

Use **VRRP via keepalived** (`services.keepalived` in NixOS).

---

## What Was Tried and Failed

| Approach | Why It Was Ruled Out |
|---|---|
| CARP | BSD-only kernel protocol. Not present in the Linux kernel. |
| ucarp (userspace CARP for Linux) | Unmaintained since ~2018. No NixOS module. Wrong foundation for production use. |
| Static manual cutover only | Already in place as the fallback (`docs/router-spare-cutover.md`), but requires manual cable moves. Not a failover protocol. |

---

## Consequences

### Positive

- keepalived is well-maintained and is the standard Linux VRRP implementation
- NixOS `services.keepalived` module: zero-friction declarative configuration
- VRRP v3 supports IPv4 and IPv6
- Integrates with notify scripts for driving Stork server, WAN MAC cloning, and
  Kea state on role transition
- VRRP patent concerns are moot — the original Cisco patents have expired

### Negative / Trade-offs

- VRRP uses a simple text password for peer authentication, not a
  cryptographic HMAC like CARP uses. On an isolated LAN segment this is
  acceptable; on a shared or untrusted segment it would not be.
- keepalived's VRRP implementation has historically had CVEs related to
  privilege escalation in its scripting path. The notify scripts must not
  accept untrusted input.

### Constraints Introduced

- The gateway VIP approach does **not** provide firewall state continuity on
  failover. Existing TCP connections reset when the backup promotes. This is a
  separate concern addressed by ADR-002 (`conntrackd`).
- The VRRP peer authentication password is currently stored as a plaintext Nix
  string (`vrrpPassword` option). This is acceptable for a homelab LAN but
  should be moved to an agenix secret if the threat model changes.

---

## Why OPNsense Uses CARP and We Do Not

OPNsense runs on FreeBSD/HardenedBSD. CARP is a first-class FreeBSD kernel
protocol with deep `pf` integration (`pfsync` for state sync, `ifconfig` for
management). It is the natural choice on that platform for the same reason
keepalived is the natural choice on Linux: it is what the kernel natively
provides and what the ecosystem supports.

This is not a limitation of the Linux approach — VRRP and CARP solve the same
problem. The Linux ecosystem simply chose a different protocol name and a
different implementation lineage.

---

## Verification

- keepalived running on both routers: `systemctl status keepalived`
- VIP present on active node: `ip addr show | grep 10.10.10.1`
- VIP absent on backup: same check on backup
- Failover test: `systemctl stop keepalived` on primary; VIP appears on backup
  within `advert_int` (default 1s) + `preempt_delay`
