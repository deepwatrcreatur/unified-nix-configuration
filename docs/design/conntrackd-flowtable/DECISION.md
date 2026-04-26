# Decision: conntrackd + nftables Flowtable

**Date:** 2026-04-25
**Status:** Closed
**Decided by:** Calder (IC)
**Evidence:** ACTIVE_DISCUSSION.md — positions from Codex (×2), Gemini (×2), IC final synthesis

---

## Q1 — Offloaded flows survive failover: YES — with version constraint

**Mechanism:**
- The OFFLOAD bit toggle does not emit a ctnetlink event. The backup's
  event-driven cache retains each flow as ESTABLISHED — the last replicated
  state before offload.
- On startup/bulk resync, conntrackd reads the full kernel table including
  IPS_OFFLOAD entries and stores them in the backup cache with the bit set.
- On failover, `conntrackd -c` injects cache entries into the kernel.
  The kernel's `nf_ct_change_status_common` rejects any entry with
  `IPS_OFFLOAD` set, returning `-EBUSY`.
- **conntrack-tools 1.4.8** (current nixpkgs) does not strip this bit before
  injection. This means dump-sourced OFFLOAD entries fail to inject.
- **conntrack-tools 1.5.0** fixes this: commit `8a8d1b1167c1`
  ("conntrackd: ignore IPS_OFFLOAD and IPS_HW_OFFLOAD bits") strips
  bits `0x4000` and `0x8000` before writing, allowing injection to succeed.
- After successful injection, the first packets miss the flowtable (entry not
  yet re-offloaded), fall through to the nftables forward chain, match
  `ct state established accept`, and are forwarded. Re-offload occurs after
  a few packets.

**Operational exposure:** `StartupResync` defaults to disabled in FTFW mode.
The poisoned-cache window is therefore bounded to: explicit startup resync,
manual/peer-triggered resync, and netlink overrun recovery (default 30s after
overrun). The fix is required for correctness but not triggered on every
conntrackd restart in standard configuration.

**Implication for implementation:**
- Standard FTFW mode is correct. `StartupResync` should remain at its default
  (disabled) unless there is a specific reason to enable it.
- **Local derivation patch required against conntrack-tools 1.4.8.** No
  confirmed upstream release contains the fix. Latest upstream tag is 1.4.9;
  its changelog does not include the OFFLOAD-bit masking change.
- The patch: in `src/netlink.c`, mask out `IPS_OFFLOAD` (0x4000) and
  `IPS_HW_OFFLOAD` (0x8000) from the status field in both
  `nl_create_conntrack` and `nl_update_conntrack` before writing to the
  kernel. Equivalent to `status &= ~(IPS_OFFLOAD | IPS_HW_OFFLOAD)`.
- If a future nixpkgs update ships a version that verifiably contains this
  fix, drop the local patch and take the package from nixpkgs directly.
- No special OFFLOAD-aware configuration knobs needed — the fix is in the
  injection path, transparent to the operator.

**Validation requirement:** Live test with a long-lived already-offloaded
connection (e.g., an active `iperf3` or `scp` session running long enough
to be offloaded) must survive failover without reset. A test that only checks
short-lived connections does not exercise this path.

---

## Q2 — NixOS module: NONE EXISTS

`conntrack-tools` 1.4.8 is packaged. There is no `services.conntrackd` NixOS
module in the current nixpkgs.

**Implication for implementation:** `router-ha.nix` must:
1. Generate `/etc/conntrackd/conntrackd.conf` from typed Nix options
2. Define a systemd service unit that runs `conntrackd -C /etc/conntrackd/conntrackd.conf`
3. The option schema should expose at minimum: sync interface, local address,
   peer address, FTFW mode toggle, and commit timeout

---

## Q3 — Failover sequence

```
notify_master:
  1. conntrackd -c               # commit external cache → kernel
  2. ip link set <wan> address <cloned-mac>
     ip link set <wan> up
     systemctl restart systemd-networkd   # WAN takeover
  3. systemctl start kea-dhcp4-server    # \  parallel or
  4. systemctl start stork-server        # /  sequential, order-independent
```

Steps 3 and 4 are application-layer; they do not affect TCP connection
continuity and may start in any order after step 2.

```
notify_backup / notify_fault:
  1. conntrackd -f               # flush internal cache
  2. ip link set <wan> down      # WAN release
  3. systemctl stop kea-dhcp4-server
  4. systemctl stop stork-server
```

---

## Work item 39 — unblocked with constraints

Update `docs/router-work-items/39-conntrackd-firewall-state-sync.md`:
- Status: `ready`
- Add live-validation requirement for already-offloaded flows
- Add the sequencing above to the implementation spec
- Add the "no NixOS module" constraint to the scope
- **Add:** conntrack-tools ≥ 1.5.0 required; check nixpkgs version and add
  overlay or local patch if needed
