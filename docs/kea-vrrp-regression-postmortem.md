# Post-Mortem: Kea DHCP / VRRP Regression (2026-04-23)

**Status:** Partially resolved — primary router serving DHCP; HA pair not yet at matched deployment
**Incident record:** `docs/incidents/2026-04-23-dhcp-vrrp-regression/` in `nix-router-optimized`

---

## What Happened

During the VRRP/HA transition, fresh LAN clients stopped receiving DHCP leases from the primary router. Existing clients were unaffected (unicast renewal bypasses the broken path). The regression was not a single bug — it was four separate issues stacked on each other, each masking the next.

---

## Root Causes (in discovery order)

### 1. Address-qualified interface in raw socket mode

Kea 3.x on Linux fails to register a `PF_PACKET` raw socket for polling when the interface is specified with an address qualifier (e.g., `enp6s16/10.10.10.2`). The Linux Packet Filter does not watch the FD. The daemon starts without error, binds without error, and `ss` shows the socket open — but `strace` reveals no `recvmsg()` calls arrive on it.

**This is a Kea 3.x defect** (or at minimum an undocumented and surprising behaviour). The upstream NixOS module `services.kea.dhcp4.settings` is an untyped attrset passthrough with no interface format validation, so nothing stops the broken form from being written.

**Fix:** Always use bare interface names (`enp6s16`). The `router-kea` NixOS module now enforces this with a build-time assertion that fails if any interface contains `/`.

### 2. HA state silence masking broadcast receive

Once the address-qualified interface was corrected, clients still did not receive IPs. `strace` showed `recvmsg()` succeeding on the `PF_PACKET` FD — broadcasts were being read. But no `DHCP4_PACKET_RECEIVED` appeared in the journal.

The cause: Kea HA in the `READY` and `WAITING` states reads packets off the socket and then silently discards them before passing them to the DHCP processor. This is documented Kea behaviour — the server defers to the peer when it believes the peer is available — but it makes the server look completely blind at the socket level.

**This is not a Kea bug** but it is a severe UX failure. Operators who correctly diagnose the socket layer (tcpdump → strace → ss) will conclude "the application is deaf" when the actual problem is one level up. The SOP now includes an explicit HA state mask check before socket debugging is considered complete.

**Fix:** Force the HA state machine to `PARTNER-DOWN` (either by stopping the peer or by exceeding `max-response-delay`). Document in `DHCP_SELECTION.md` that HA state convergence must be verified before any socket-layer debugging begins.

### 3. Localhost self-URL regression in HA config

Even after clearing the socket issue, the HA pair settled into a persistent asymmetric state: primary in `READY` (DHCP disabled), secondary in `PARTNER-DOWN` (DHCP enabled). Root cause: commit `65a57b4` in `nix-router-optimized` set the HA listener self-URL to `http://127.0.0.1:8000/`. The peer cannot reach `127.0.0.1` on another host, so the primary was unreachable for heartbeats.

This regression arrived via an unpinned flake input and was not caught by any build-time check (the config evaluates successfully with a localhost URL).

**Fix:** Added `services.router-kea.dhcp4.ha.localAddress` as an explicit option with a `WARNING: 127.0.0.1 will break HA` note in the description. The option defaults to `0.0.0.0` which, unlike `127.0.0.1`, is reachable by peers. Production wiring uses per-node LAN IPs (`10.10.10.2`, `10.10.10.3`).

### 4. Missing `libdhcp_lease_cmds.so` hook dependency

Once HA peers could actually reach each other, sync failed with `'lease4-get-page' command not supported`. The Kea HA hook requires `libdhcp_lease_cmds.so` to be loaded alongside `libdhcp_ha.so` for lease synchronisation. This dependency is not mentioned in Kea's HA quickstart documentation.

**Fix:** `router-kea.nix` now unconditionally loads both hooks when HA is enabled:
```nix
hooks-libraries = mkIf cfg.dhcp4.ha.enable [
  { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_lease_cmds.so"; }
  { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_ha.so"; ... }
];
```

---

## What Was NOT a Bug

- The "Third-State" runtime (`raw` + bare interface + `use-routing`) is correct and now verified. `strace` confirmed successful `recvmsg()` on the `PF_PACKET` socket.
- The `server-id` crash seen during the incident was a generation-specific artifact from an out-of-sync deployment, not a property of the current source.

---

## What Remains Open

- `router-backup` is still running the old management-plane HA config (`192.168.100.x` URLs) while `router` is on the new LAN-plane config (`10.10.10.x` URLs). Full HA validation requires deploying both nodes to a matching config and confirming `LOAD-BALANCING` state on both.
- See incident SUMMARY.md for the current blocker and next action.

---

## Guardrails Added

| Guardrail | Where |
|---|---|
| Build assertion: rejects address-qualified interfaces | `nix-router-optimized/modules/router-kea.nix` |
| `localAddress` option with warning against 127.0.0.1 | `nix-router-optimized/modules/router-kea.nix` |
| Auto-load `libdhcp_lease_cmds.so` when HA is enabled | `nix-router-optimized/modules/router-kea.nix` |
| `outboundInterface` defaults to `use-routing` when HA is on | `nix-router-optimized/modules/router-kea.nix` |
| HA mask check in Phase 3 of the forensic SOP | `standards/agentic-orchestration/SOP_FORENSIC_ENGINEERING.md` |
| Kea complexity warning in DHCP selection guide | `nix-router-optimized/docs/DHCP_SELECTION.md` |

---

## Lessons for Future Incidents

1. **Observe before changing.** Socket-layer evidence (`strace`, `tcpdump`, `ss`) was necessary but not sufficient. HA state (`config-get`, `ha-heartbeat` response) is a separate layer that must be checked independently.
2. **The mask check is not optional.** At least two distinct layers here looked like socket failures but were caused by higher-layer state. Follow the SOP Phase 3 mask checklist before concluding "the network stack is broken."
3. **Pin flake inputs for production changes.** The `localAddress` regression arrived silently via an unpinned input. An explicit `nix flake update nix-router-optimized` step with a required build would have surfaced it.
4. **Deployment mismatch is its own failure mode.** Even a correct source config is invisible until both nodes are deployed to it. The incident record must track deployed state separately from source state.
