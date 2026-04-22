# Memory Archive: -home-deepwatrcreatur-flakes / fe6d61b0

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/fe6d61b0-2b77-442d-80ec-6450e18807ef.jsonl`  
**Date**: 2026-03-28  
**Findings**: 3

---

## Finding 1 (score=2, role=assistant, ts=2026-03-28T03:08:01.059Z)

Yes, you're missing it. The four `nix-darwin` CLI tools (`darwin-option`, `darwin-rebuild`, `darwin-version`, `darwin-uninstaller`) are not anywhere in your config — they're provided by the `nix-darwin` flake itself, not nixpkgs.

Note that your `just.nix` hardcodes the full path `/nix/var/nix/profiles/system/sw/bin/darwin-rebuild` precisely because `darwin-rebuild` isn't on the PATH as a package — which would be unnecessary if you added it properly.

The natural home for this is `modules/nix-darwin/common/packages.nix`. Want me to add it there?

---

## Finding 2 (score=2, role=assistant, ts=2026-03-28T03:08:59.802Z)

Important distinction: nix-darwin `system.stateVersion` is an integer (currently `6`) — it's not the same versioning scheme as NixOS. Bumping it to `7` would be a breaking state change and needs to be done carefully on the actual Mac.

What you're likely thinking of is the **nixpkgs channel** being used for Darwin. Let me check what the flake is pointing to.

---

## Finding 3 (score=2, role=assistant, ts=2026-03-28T03:10:26.974Z)

`mac-app-util` is **disabled** due to an `sbcl` build failure. That's why Spotlight can't find your Nix apps.

The module you pasted is a manual workaround that does what `mac-app-util` does — creates `~/Applications/Nix Apps/` with proper `.app` copies. You don't need that specific module snippet because:

1. You already have `mac-app-util` properly set up in the flake — just the import is commented out
2. The manual script is inferior (it's a partial reimplementation, `mac-app-util` handles edge cases better)

The right fix is to resolve the `sbcl` build failure blocking `mac-app-util`. That's likely a nixpkgs issue — `sbcl` is a build dependency of `mac-app-util`. It may be fixed in `nixos-25.11` already. Want me to try re-enabling the import and see if it evaluates now?

---
