# Memory Archive: -home-deepwatrcreatur-flakes / 4a2986a4

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/4a2986a4-ae82-4daa-9c06-e05cd0fdebba.jsonl`  
**Date**: 2026-03-28  
**Findings**: 1

---

## Finding 1 (score=4, role=user, ts=2026-03-28T02:01:17.893Z)

This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

Summary:
1. Primary Request and Intent:
   - Study `nix-router-optimized/` and add suggestions to `docs/improvements.md`
   - Implement all the improvements listed in improvements.md
   - Verify the changes work (`nix flake check`, `nix build`)
   - Commit and push the changes, then deploy to the gateway host
   - Investigate CI failures on nix-ci.com for the `unified-nix-configuration` repo (PR #31, `feat/ci-and-lxc-networking-check` branch)

2. Key Technical Concepts:
   - NixOS flakes and module system (`mkDefault`, `mkIf`, `mkEnableOption`, assertions)
   - systemd service hardening (`PrivateUsers`, `AmbientCapabilities`, `CapabilityBoundingSet`)
   - nftables firewall rules (flowtable, rate limiting, mutual exclusion)
   - Conntrack kernel module parameters (`boot.extraModprobeConfig`)
   - Grafana provisioning and password management
   - `nix flake lock` / lock file `follows` path notation vs pinned node entries
   - Gateway deployment via SSH using `nixos-rebuild switch --flake github:...`
   - nix-ci.com evaluation: reads flake from read-only git URL, fails if lock file needs modification
   - `llm-agents` intentionally not following root nixpkgs (preserves garnix.io binary cache hashes)

3. Files and Code Sections:

   - **`nix-router-optimized/modules/router-networking.nix`**
     - Fixed `systemd.network.wait-online.enable = mkIf cfg.waitOnline true` → `= cfg.waitOnline` (false was a no-op)
     - Fixed `DHCPServer = false` → `DHCPServer = mkDefault false` (prevented router-dhcp from overriding — pre-existing bug causing `nix build` to fail)

   - **`nix-router-optimized/modules/router-optimizations.nix`**
     - Removed `ethtool -K $iface ufo on` (UFO removed from kernel 4.15)
     - Removed `sleep 2` (anti-pattern; interface check already handles missing interfaces)
     - Removed entire `xdp-firewall`

---
