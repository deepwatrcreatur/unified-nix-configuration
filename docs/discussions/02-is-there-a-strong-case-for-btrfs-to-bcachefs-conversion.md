# Discussion 02: Is There a Strong Case to Convert Any Host from Btrfs to bcachefs?

**Status:** closed
**Scope:** `unified-nix-configuration`
**Date:** 2026-05-23

## Why this discussion exists

Several NixOS hosts in this repo are explicitly standardized on Btrfs today:

- `hosts/nixos/router/disko.nix`
- `hosts/nixos/router-backup/disko.nix`
- `hosts/nixos/inference-vm/modules/disko.nix`
- `hosts/nixos/workstation/hardware-configuration.nix`
- `hosts/nixos/phoenix/hardware-configuration.nix`

The repo also has explicit Btrfs-era operational assumptions:

- `modules/nixos/snapper.nix` hard-codes `FSTYPE = "btrfs"` for `/` and `/home`
- bootstrap and recovery docs assume Btrfs tools, subvolumes, and snapshot
  workflows
- there are currently no `bcachefs` references in the repo

This discussion asked whether any host has a strong enough reason to break from
that standardized model.

## Participation record

This was a **real four-seat round** with substantive responses from:

- Codex CLI
- Gemini CLI
- DeepSeek API
- OpenCode free-model enrichment seat

An additional Claude CLI follow-up was attempted during archival but did not
produce usable text in time, so it is not counted in the synthesis below.

## Voice summaries

### Codex CLI

- Strongest on the distinction between a **lab experiment** and a strong
  migration case.
- Identified `inference-vm` as the least-bad experimental candidate because it
  is simpler and less infrastructure-critical than the router or workstation.
- Emphasized that the repo is operationally standardized on Btrfs far beyond
  one disk layout: Snapper, bootstrap tooling, recovery docs, and operator
  muscle memory all depend on it.
- Bottom line: no strong case for any current host; at most, a deliberately
  experimental inference VM pilot.

### Gemini CLI

- Strongest on the argument that bcachefs's theoretical upside would be native
  tiering and encryption for inference-style storage workloads.
- Still judged the migration unjustified because the repo is effectively a
  Btrfs monoculture with shared Snapper assumptions and consistent subvolume
  layouts.
- Highlighted that the repo values recovery invariants and operational
  consistency more than filesystem novelty.
- Bottom line: no strong case for conversion now.

### DeepSeek API

- Strongest on the operational downside:
  Snapper support, documented rollback paths, and simple Btrfs subvolume
  recovery are already in place and would all be disrupted.
- Also chose `inference-vm` as the only plausible low-risk experimentation
  target.
- Judged that router/workstation roles gain nothing compelling enough from
  bcachefs to justify the operational churn.
- Bottom line: no strong case exists.

### OpenCode free-model enrichment seat

- Strongest on the narrow performance case for `inference-vm` if measurable I/O
  bottlenecks ever appear.
- But it converged that speculative gains do not outweigh the current repo's
  Btrfs-specific toolchain, docs, and recovery familiarity.
- Bottom line: no current host shows sufficient need to justify the move.

## Convergence

The round converged on five points.

1. **There is no strong present-day case for conversion.**
   No seat argued that any current host should move from Btrfs to bcachefs now
   as an operational recommendation.

2. **`inference-vm` is the only plausible experiment surface.**
   All substantive seats that named a candidate picked `inference-vm` or its
   family because it is more lab-shaped and easier to rebuild than router or
   workstation roles.

3. **The repo is standardized on Btrfs operationally, not just syntactically.**
   The cost is not only changing one `disko` stanza. It is also changing
   Snapper, bootstrap tooling, recovery instructions, and day-2 operational
   familiarity.

4. **Router and workstation roles are the wrong place for filesystem
   experimentation.**
   These hosts benefit more from boring recoverability than from speculative
   filesystem upside.

5. **Any future bcachefs move would need a concrete workload-driven trigger.**
   A real case would likely require measurable inference-storage pain or a
   narrow lab objective, not general enthusiasm.

## Maintained line

The maintained line after this round is:

- keep current hosts on the repo's established Btrfs + Snapper model
- do not introduce bcachefs into router, router-backup, workstation, or phoenix
  as a proactive migration
- if bcachefs is explored at all, treat it as a bounded `inference-vm`
  experiment with explicit acceptance that it diverges from the repo's normal
  recovery and documentation model

## Bottom line

There is **not** a strong case to convert any current NixOS host in
`unified-nix-configuration` from Btrfs to bcachefs.

The only defensible exception would be a deliberate experiment on an
`inference-vm` host if a concrete storage-performance question appears and the
team is willing to absorb one-off filesystem divergence for that lab purpose.
