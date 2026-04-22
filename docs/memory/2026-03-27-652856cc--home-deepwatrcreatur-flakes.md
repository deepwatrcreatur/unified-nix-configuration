# Memory Archive: -home-deepwatrcreatur-flakes / 652856cc

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/652856cc-c48a-4b68-b815-8fb6992192b6.jsonl`  
**Date**: 2026-03-27  
**Findings**: 1

---

## Finding 1 (score=3, role=assistant, ts=2026-03-27T11:50:59.594Z)

Yes, I found the bug. The custom `gnome-keyring-daemon` systemd service in `gnome.nix:174-185` is conflicting with GNOME's own keyring management. When `services.desktopManager.gnome.enable = true`, NixOS/gnome-session already starts gnome-keyring — the custom service starts a second instance, causing the ABRT crash.

The fix is two parts:
1. Remove the custom service (it's redundant and conflicting)
2. Add proper PAM integration for auto-login so the keyring actually unlocks

Here's what needs to change:

---
