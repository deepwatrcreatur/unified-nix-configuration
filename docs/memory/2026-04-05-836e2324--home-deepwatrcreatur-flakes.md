# Memory Archive: -home-deepwatrcreatur-flakes / 836e2324

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/836e2324-1849-48ee-a5bc-d2a8cb5aded9.jsonl`  
**Date**: 2026-04-05  
**Findings**: 1

---

## Finding 1 (score=2, role=assistant, ts=2026-04-05T04:57:00.452Z)

The issue is that Codex hardcodes the check for bubblewrap at `/usr/bin/bwrap`, but on NixOS packages land in the Nix store, not `/usr/bin/`. The fix needs two parts: install bubblewrap and create a symlink at the expected path.

The right place is the workstation `profile.nix`. I'll add bubblewrap to `environment.systemPackages` and use `systemd.tmpfiles.rules` to create the symlink:

---
