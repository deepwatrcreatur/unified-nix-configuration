# Memory Archive: -home-deepwatrcreatur-flakes / 48e53647

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/48e53647-1474-4b2a-bb7a-569b26a3bbc8.jsonl`  
**Date**: 2026-03-30  
**Findings**: 1

---

## Finding 1 (score=2, role=assistant, ts=2026-03-30T16:45:36.736Z)

The lock file has `@xmldom/xmldom` 0.8.11, consistent with our current hash. The hash was never stale locally — the issue was likely on the remote build.

The correct general solution: commit the generated `package-lock.json` to the nix-markit flake repo and use `importNpmLock { npmRoot = ./.; }`. This eliminates `npmDepsHash` entirely — integrity hashes live in the lock file itself. This is the standard nixpkgs pattern for npm packages.

---
