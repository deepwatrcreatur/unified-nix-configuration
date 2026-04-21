# Robot Triage with beads_viewer (bv)

`bv --robot-triage` is the primary recommendation engine for agent task
selection once the `.beads/` store is populated.

## Prerequisites

1. **`beads-rust` installed** — the repo-managed wrapper around the
   `beads_rust` CLI creates and manages the store.
   Enabled on workstation via `programs.beads.enable = true`.
2. **Store initialised** — run `beads-rust init` in the repo root once.
3. **Items migrated** — run `scripts/beads-migrate-tooling.sh` to import
   the current markdown queue into beads.
4. **`bv` installed** — the `beads_viewer` TUI; enabled alongside `beads-rust`.

## Quick Reference

```bash
# Top-ranked unblocked task (agent-optimised one-liner):
bv --robot-triage --labels tooling --json | jq -r '.[0] | "\(.rank). \(.title) (p=\(.pagerank_score | . * 100 | round))"'

# Full ranked list as JSON:
bv --robot-triage --labels tooling --json

# Interactive TUI (human-friendly graph view):
bv

# All labels (router + tooling together):
bv --robot-triage --json
```

## Interpreting the Scores

| Field | Type | Meaning |
|-------|------|---------|
| `rank` | int | Overall position (1 = highest priority) |
| `pagerank_score` | float 0–1 | Fraction of "incoming dependency weight"; a task many others depend on scores high |
| `critical_path_rank` | int | Position on the longest chain of blocked work; 1 = most blocking |
| `blocking_count` | int | Number of tasks directly waiting on this one |
| `depth` | int | Distance from the root of the dependency DAG |

### Practical rules

- **High pagerank + low critical_path_rank** → do this now; many things
  unblock once it is done.
- **Low pagerank + high critical_path_rank** → it is on the longest chain
  but not widely referenced; still time-critical if that chain is the goal.
- **High pagerank + high critical_path_rank** → review manually; this task
  may have stale edges or circular references.
- **Tied scores** → prefer the item ranked higher in `README.md` (human
  signal still matters for context).

## Workflow Integration

```bash
# 1. Sync the store with the latest markdown queue state
scripts/beads-migrate-tooling.sh

# 2. Ask bv what to do next
NEXT=$(bv --robot-triage --labels tooling --json | jq -r '.[0].id')
beads-rust start "$NEXT"

# 3. Do the work...

# 4. Close the bead and let bv update its graph
beads-rust finish "$NEXT"
```

## Graph-Aware Re-ranking

Unlike the static README ordered list, `bv` re-ranks dynamically as tasks
are completed or new dependency edges are added. After `beads-rust finish` closes a
bead, the next `bv --robot-triage` call will reflect the freed-up blockers.

To add dependency edges:

```bash
# task B depends on (is blocked by) task A:
beads-rust link A B --type blocks
```

## Bootstrapping

If the `.beads/` store does not exist yet:

```bash
cd ~/flakes/unified-nix-configuration
beads-rust init
scripts/beads-migrate-tooling.sh
bv --robot-triage --labels tooling --json | jq '.[0:3]'
```

The `beads-migrate-tooling.sh` script reads the current README queue and
creates beads for all `ready` and `in-progress` items.  Dependency edges
must be added manually after initial import.
