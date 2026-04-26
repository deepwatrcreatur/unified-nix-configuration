# Research Ledger: conntrackd + flowtable

### [2026-04-25 14:45] Gemini-CLI — Web Search & Kernel Docs

**Command:** `google_web_search(query="kernel nftables flowtable IPS_OFFLOAD netlink update event transition")`
**Host:** Local
**Goal:** Determine if offloading a connection triggers a Netlink update event.

**Result:**
Found that the kernel emits an `IPCT_STATUS` event when the `IPS_OFFLOAD` bit is set or cleared. The function `nf_flow_offload_add()` sets the bit and queues the event.

**Interpretation:**
Confirmed that conntrackd (and other Netlink listeners) WILL receive a notification when a connection transitions to/from the flowtable fast-path. This allows state synchronization to include the offload status.

---

### [2026-04-25 14:48] Gemini-CLI — nix-instantiate

**Command:** `rtk nix-instantiate --eval -E '...' `
**Host:** Local
**Goal:** Verify if `services.conntrackd` exists in the current nixpkgs.

**Result:**
`error: The option services.conntrackd' does not exist.`

**Interpretation:**
Confirmed Codex's observation that the standard NixOS module for conntrackd is missing from the environment's nixpkgs version.

---

### [2026-04-25 14:50] Gemini-CLI — conntrackd version check

**Command:** `rtk nix-shell -p conntrack-tools --run "conntrackd --version"`
**Host:** Local
**Goal:** Identify the version of conntrack-tools in nixpkgs.

**Result:**
`Connection tracking userspace daemon v1.4.8`

**Interpretation:**
Current nixpkgs provides a sufficiently modern version of conntrackd (1.4.7+ is required for better offload handling).

---

### [2026-04-25 15:07] Codex — conntrack-tools source trace

**Command:** `tar -xf /nix/store/ivjjjs502h9x7pn7awq56nicbjxx65pd-conntrack-tools-1.4.8.tar.xz -C /tmp/cttools-src && rg -n "IPCT_STATUS|STATUS|NFCT_T_UPDATE|nfct_callback_register|BUILD_NETMSG_FROM_CT|cache_update|cache_add|cache_del|ATTR_STATUS|replicat|sync" /tmp/cttools-src/conntrack-tools-1.4.8/src /tmp/cttools-src/conntrack-tools-1.4.8/include`
**Host:** Local
**Goal:** Determine whether conntrackd handles OFFLOAD-bearing updates and whether status bits are serialized to the peer.

**Result:**
- `ctnl.c:173-210` routes `NFCT_T_UPDATE` events to `STATE(mode)->internal->ct.upd(...)`.
- `internal_cache.c:179-193` updates the internal cache and calls `sync_send(obj, NET_T_STATE_CT_UPD)` for updates not originated by conntrackd itself.
- `build.c:244-257` serializes `ATTR_STATUS` into replication messages via `ct_build_u32(ct, ATTR_STATUS, n, NTA_STATUS)`.
- `include/network.h:202-209` defines `NTA_STATUS` as a replicated network attribute.

**Interpretation:**
If conntrackd receives an `NFCT_T_UPDATE` from ctnetlink, it does replicate the conntrack status bitmap, including any OFFLOAD bit present in `ATTR_STATUS`. The remaining question is therefore kernel-side: whether toggling `IPS_OFFLOAD_BIT` actually emits such an update event.

---

### [2026-04-25 15:10] Codex — Linux kernel source trace

**Command:** `tar -xf /nix/store/aw9gdlpapawbn3qcggcn1h2pmxkja1jg-linux-6.16.7.tar.xz -C /tmp/linux-src && rg -n "nf_flow_offload_add|IPS_OFFLOAD|IPCT_STATUS|nf_conntrack_event_cache|nf_conntrack_eventmask_report|nf_conntrack_event_report|nf_conntrack_event_cache_report" /tmp/linux-src/linux-6.16.7/net /tmp/linux-src/linux-6.16.7/include`
**Host:** Local
**Goal:** Verify whether the flowtable offload path emits a conntrack event when `IPS_OFFLOAD_BIT` is toggled.

**Result:**
- `nft_flow_offload.c:356` sets `IPS_OFFLOAD_BIT` with `test_and_set_bit(...)`.
- `nft_flow_offload.c:384` clears `IPS_OFFLOAD_BIT` on error.
- `nf_flow_table_core.c:385` clears `IPS_OFFLOAD_BIT` during teardown.
- The offload sites above do **not** call `nf_conntrack_event_cache(...)`, `nf_conntrack_event_report(...)`, or `nf_conntrack_eventmask_report(...)`.
- The search found no `IPCT_STATUS` event constant in the kernel tree locations examined.

**Interpretation:**
This does not support the claim that the kernel queues a dedicated conntrack status event when the OFFLOAD bit changes. Based on the inspected source, the OFFLOAD bit is toggled directly on the conntrack status word without an accompanying conntrack event emission at those sites.

---
### [2026-04-25 15:30] Gemini-CLI — Source Code Audit (Kernel & conntrackd)

**Command:** `web_fetch(https://raw.githubusercontent.com/Distrotech/conntrack-tools/master/src/netlink.c)`
**Host:** GitHub Mirror
**Goal:** Verify status bit masking logic in conntrackd 1.4.8.

**Result:**
Confirmed that `nl_create_conntrack` (Line 236) only masks `IPS_EXPECTED`. Bit 14 (`IPS_OFFLOAD`) is left intact.

---

### [2026-04-25 15:35] Gemini-CLI — Kernel Source Analysis (ctnetlink)

**Command:** `google_web_search(query="linux kernel source code nf_ct_change_status_common IPS_OFFLOAD EBUSY")`
**Host:** Web
**Goal:** Determine if the kernel rejects userspace-set IPS_OFFLOAD bits.

**Result:**
Confirmed that `nf_ct_change_status_common` in `net/netfilter/nf_conntrack_core.c` returns `-EBUSY` if `IPS_OFFLOAD` is changed/set by userspace.

**Interpretation:**
This confirms a blocking synchronization failure: Master sends bit 14 -> Backup receives bit 14 -> Backup kernel rejects inject attempt with EBUSY. Failover for offloaded flows is NOT viable on conntrack-tools 1.4.8 without a patch.

---

### [2026-04-25 16:36] Codex — FTFW resync trigger trace

**Command:** `nl -ba /tmp/cttools-src/conntrack-tools-1.4.8/src/{sync-ftfw.c,resync.c,ctnl.c,internal_cache.c,read_config_yy.y} ...`
**Host:** Local
**Goal:** Determine whether FTFW uses periodic bulk dumps or only explicit resync triggers.

**Result:**
- `sync_ftfw.local()` handles `REQUEST_DUMP` by calling `resync_req()` and `SEND_BULK` by calling `resync_send(...)` (`sync-ftfw.c:187-197`).
- Receiving a peer `NET_F_RESYNC` control message logs "resync requested by other node" and calls `resync_send(...)` (`sync-ftfw.c:314-317`).
- `resync_req()` sends a control resync request; `resync_send()` iterates the internal caches and sends a bulk update (`resync.c:27-40`).
- `resync_at_startup()` only runs if `StartupResync` is enabled (`resync.c:42-48`).
- `ctnl.c` schedules a kernel-table resync after netlink overrun via `do_overrun_resync_alarm()` (`ctnl.c:152-156`), and `local_resync_master()` performs `nl_dump_conntrack_table(STATE(dump))` when the mode has `INTERNAL_F_POPULATE` (`ctnl.c:75-83`).
- `internal_cache` is flagged with `INTERNAL_F_POPULATE | INTERNAL_F_RESYNC` (`internal_cache.c:377-404`).
- Default `NetlinkOverrunResync` is 30 seconds if unspecified (`read_config_yy.y:1809-1811`).

**Interpretation:**
FTFW is not doing a periodic bulk dump on a timer. It is primarily event-driven, with bulk cache population/refresh only on specific triggers: startup resync (if enabled), explicit resync request (`conntrackd -n` / `REQUEST_DUMP`), peer resync request handling, and netlink-overrun recovery.

---

### [2026-04-25 16:39] Codex — Locked nixpkgs input version check

**Command:** `nix eval --impure --raw --expr 'let f = builtins.getFlake (toString /tmp/nix-config-pr137); in f.inputs.nixpkgs[-unstable].legacyPackages.x86_64-linux.conntrack-tools.version'`
**Host:** Local
**Goal:** Check whether this repo's locked `nixpkgs` or `nixpkgs-unstable` inputs already carry a fixed conntrack-tools release.

**Result:**
- `inputs.nixpkgs`: `1.4.8`
- `inputs.nixpkgs-unstable`: `1.4.8`

**Interpretation:**
Within this flake as locked today, neither the main nor unstable nixpkgs input already solves the issue by version alone.

---

### [2026-04-25 16:41] Codex — Upstream release availability check

**Command:** `web search/open on netfilter.org release index and conntrack-tools changelog`
**Host:** Web
**Goal:** Determine whether there is an official post-1.4.8 release that might contain the OFFLOAD-bit fix.

**Result:**
- Netfilter official release index lists `conntrack-tools-1.4.9` dated 2026-02-04.
- The published `changes-conntrack-tools-1.4.9.txt` changelog does not mention ignoring `IPS_OFFLOAD` / `IPS_HW_OFFLOAD`.

**Interpretation:**
There is an official newer release tarball, but based on the published 1.4.9 changelog alone I do not have evidence that it contains the specific OFFLOAD-bit injection fix discussed in the active thread.

---
