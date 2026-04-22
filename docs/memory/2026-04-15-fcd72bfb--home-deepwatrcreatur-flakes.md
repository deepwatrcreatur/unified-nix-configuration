# Memory Archive: -home-deepwatrcreatur-flakes / fcd72bfb

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/fcd72bfb-8b57-48e4-b8b9-4cf5e75179fe.jsonl`  
**Date**: 2026-04-15  
**Findings**: 1

---

## Finding 1 (score=2, role=assistant, ts=2026-04-13T06:05:18.120Z)

Yes, Tailscale is already there. Now I have a clear picture of the conflicts. Let me summarize what I found:

**Tailscale already in the flake:** `modules/router-tailscale.nix` is complete and wired into `nixosModules.default`. It hooks into `services.router-firewall.tailscaleInterface` (singular, named option) and `wanUdpPorts`.

**Conflicts if both are enabled simultaneously:**

**1. UDP port 51820 — hard conflict**
Both Tailscale (line 124 of tailscale module) and Netbird (nixpkgs default) bind the same UDP port. The second daemon to start will fail. Easy to fix: `router-netbird` defaults to `51821`, and we add a cross-module assertion.

**2. `tailscaleInterface` in router-firewall — architectural mismatch**
This is the main structural issue. The firewall currently has a single `nullOr str` option hardcoded for Tailscale that generates these rules:

```
# input chain
iifname "tailscale0" accept

# forward chain  
iifname "tailscale0" oifname {all-router-ifaces} accept
iifname {trusted-ifaces} oifname "tailscale0" accept
```

`extraTrustedInterfaces` alone doesn't generate those forward rules — Netbird traffic wouldn't be able to forward through the router without them. The fix is to generalize `tailscaleInterface` → `overlayInterfaces` (a list), and keep `tailscaleInterface` as a backward-compat alias. The Tailscale module migrates to use `overlayInterfaces`, and the Netbird module uses the same mechanism.

**Non-conflicts (safe to run both):**
- Interface names: `tailscale0` vs `nb-<name>` — no overlap
- IP forwarding / `rp_filter`: both write the same sysctl values — NixOS's `mkDefault` means last writer wins but they agree on the value
- Trusted interface lists: additive, no problem
- DNS resolvers: both can bind to different addresses

---

**The plan:**

1. **`router-firewall.nix`**: Add `overlayInterfaces` (list, replaces the singleton logic). Keep `tailscaleInterface` as a deprecated alias that appends to the list. Generate the input/forward rules for all 

---
