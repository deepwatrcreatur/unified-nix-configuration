# beads_rust Migration Plan

This document captures the design for replacing the hand-rolled markdown
work-item queue in `docs/*/` with `beads_rust`, a Rust-based local-first task
tracker built specifically for agentic workflows. In this repo, the
repo-managed command is `beads-rust`, which wraps the upstream `br` binary to
avoid colliding with the Homebrew `beads_viewer` `br` command.

**Status: In progress.** Initial `.beads/` wiring, ignore rules, repo-managed
CLI packaging, and START-HERE/agent-prompts updates are in place; actual
`beads-rust init` and queue migration remain pending on deployment.

---

## Why consider it at all

The current system works well for small queues but has several friction points
that accumulate as queue size grows:

| Pain point | Current system | beads_rust |
|---|---|---|
| Discovering next unblocked task | Agent reads README ranking + checks each file | `beads-rust ready --json` — one call |
| Claiming a task atomically | Edit the markdown file in a branch | `beads-rust claim <id>` — atomic assign + status |
| Expressing dependencies | Informal "blocked-by" prose | First-class `dep add` with typed relationships |
| Priority | Ordered list in README (manual reorder) | Numeric field; `bv --robot-triage` for graph-aware routing |
| Status transitions | Text edit inside the file | `beads-rust update --status` or `beads-rust close` |
| Searching history | `grep` across closed files | `beads-rust search <query>` (BM25 full-text) |
| Multiple queues | Separate `tooling-work-items/` and `router-work-items/` | Single `.beads/` store; differentiated by labels or epics |

The markdown system has one advantage beads doesn't: rich prose that explains
*why* a task exists, with non-goals, validation steps, and implementation notes
that read well in GitHub PR diffs. beads has `description`, `notes`, and
`acceptance_criteria` fields, but they are plain text stored in JSONL, not
markdown files visible in the GitHub file tree.

**Likely mitigation:** keep a short prose section in `description` per bead;
link to a richer doc in `docs/` from `external_ref` only when the task is
genuinely complex. Most items are simple enough that a two-line description
suffices.

---

## Field mapping

| Markdown field | beads field | Notes |
|---|---|---|
| `# Title` | `title` | Direct mapping |
| `Status: ready/in-progress/done/blocked` | `status` | `Open → InProgress → Closed`; `Blocked` is native |
| `Suggested branch:` | `notes` or `external_ref` | No native branch field; store in notes |
| `## Goal` | `description` | First paragraph |
| `## Why` | `description` (continued) | Fold into description or `notes` |
| `## Scope` | `acceptance_criteria` | Maps naturally |
| `## Non-Goals` | `notes` | Append to notes |
| `## Validation` | `acceptance_criteria` | Merge with Scope |
| `## Implementation` (outcome) | `notes` (post-close) | Add as a comment after `beads-rust close` |
| `blocked-by: item-X` (informal) | `beads-rust dep add X Y --type Blocks` | First-class dependency |
| README ranked order | `priority` (0=Critical … 4=Backlog) | Numeric; `bv` handles graph-aware re-ranking |
| Queue folder (`tooling-work-items/`) | label `tooling` on each bead | Single store, differentiated by label |
| `router-work-items/` | label `router` | Same store, different label |

---

## Installation

beads_rust is not yet in nixpkgs. This repo packages the upstream flake and
wraps it as the `beads-rust` command.

```bash
beads-rust --version
```

If you intentionally install the upstream raw binary as `br` outside Nix, you
can still use the migration script by setting `BEADS_RUST_CMD=br`.

---

## Initialisation

beads uses a `.beads/` directory at the repo root. The JSONL file is
git-trackable; the SQLite database is derived and should be gitignored.

```bash
cd ~/flakes/unified-nix-configuration
beads-rust init
```

Add to `.gitignore`:
```
.beads/*.db
.beads/*.db-shm
.beads/*.db-wal
```

Track `issues.jsonl` in git. Each `beads-rust sync --flush-only` exports the SQLite
state back to JSONL for committing.

---

## Workflow for agents

### Finding next work

```bash
# Human-readable
beads-rust ready --labels tooling

# Machine-readable for agent scripts / START-HERE equivalent
RUST_LOG=error beads-rust ready --labels tooling --json
```

### Claiming a task (atomic)

```bash
RUST_LOG=error BR_ACTOR=claude-code beads-rust claim <id>
# Sets assignee=claude-code, status=InProgress atomically
```

### Completing a task

```bash
beads-rust close <id> --reason "PR #42 merged"
beads-rust comments <id> --add "Outcome: <brief summary of what changed>"
beads-rust sync --flush-only
git add .beads/issues.jsonl
git commit -m "beads: close <id> — <title>"
```

### Adding a dependency

```bash
beads-rust dep add <blocker-id> <blocked-id> --type Blocks
```

---

## Migrating the existing items

Both queues are currently empty. When the next queue is created, populate beads
directly instead of writing markdown files:

```bash
beads-rust create "Title" \
  --type Task \
  --priority 2 \
  --labels tooling \
  --description "Goal: ...\n\nScope:\n- ...\n\nNon-goals:\n- ..." \
  --acceptance-criteria "- eval clean\n- CI green"
```

If items are already in markdown and a migration is needed, use this pattern:

```bash
# For each file in docs/tooling-work-items/:
beads-rust create "$(head -1 FILE.md | sed 's/# //')" \
  --type Task \
  --priority 2 \
  --labels tooling \
  --description "$(sed -n '/## Goal/,/## /p' FILE.md)" \
  --acceptance-criteria "$(sed -n '/## Validation/,/## /p' FILE.md)"
```

For items already `done`, close them immediately after creating:
```bash
beads-rust close <new-id> --reason "Completed prior to beads adoption"
```

For this repo's tooling queue, the helper script
`scripts/beads-migrate-tooling.sh` automates this migration pattern for all
`ready` and `in-progress` items once `beads-rust` is installed and
`beads-rust init` has run.

---

## Updating START-HERE.md

Replace the current manual instructions with a beads-aware version:

```markdown
## Finding work

Run:
  beads-rust ready --labels tooling --json

Pick the highest-priority item (lowest priority number). Claim it:
  BR_ACTOR=<your-name> beads-rust claim <id>

When done, close and sync:
  beads-rust close <id> --reason "PR #<n> merged"
  beads-rust sync --flush-only
  git add .beads/issues.jsonl && git commit -m "beads: close <id>"
```

The `agent-prompts.md` dispatch prompt becomes:

```
Run `beads-rust ready --labels tooling --json` to find the next unblocked item.
Claim it with `BR_ACTOR=claude-code beads-rust claim <id>`, do the work in a
dedicated branch, and close the bead when the PR merges.
```

---

## Beads Viewer integration (optional, once beads is in use)

`bv` (beads_viewer) adds graph-theory routing on top of the bead store.
Agents query it for priority-ranked, dependency-aware task selection:

```bash
bv --robot-triage --labels tooling
```

Install separately alongside `beads-rust`. Only worth adding
once the queue regularly has 10+ items with non-trivial dependency graphs.

---

## Nix packaging

Neither the repo-managed `beads-rust` wrapper nor `bv` are in nixpkgs yet. The
simplest approach for this repo:

```nix
# In an overlay or pkgs/beads-rust.nix
beads-rust = pkgs.rustPlatform.buildRustPackage {
  pname = "beads-rust";
  version = "0.x.y";
  src = pkgs.fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_rust";
    rev = "v0.x.y";
    hash = "sha256-...";
  };
  cargoHash = "sha256-...";
};
```

Add to `modules/home-manager/common/coding-agents.nix` once packaged:
```nix
home.packages = [ pkgs.beads-rust-cli ];
```

---

## What to keep from the markdown system

Even after migrating to beads, keep:

- `docs/` — for long-form design docs, architecture notes, and planning
  documents like this one. These are not tasks; they don't belong in beads.
- `docs/*/README.md` — brief human overview of each queue area; link to
  `beads-rust list --labels <area>` output as the live queue.
- `docs/*/START-HERE.md` — updated to reference `beads-rust ready` instead of the
  ranked list.

The markdown work-item *files* (`01-foo.md`, `02-bar.md`) are the only thing
beads replaces. Everything else stays.

---

## Trigger conditions

Migrate when **two or more** of these are true:

- A queue reaches 8+ items and manually maintaining the README ranking becomes
  error-prone.
- Two agents work a queue simultaneously and race on status edits in the same
  markdown file.
- A task's blocked-by relationship is missed because it was written in prose
  and an agent didn't read it carefully.
- The queue has a non-trivial dependency graph that makes priority ordering by
  hand brittle.
- An item is accidentally started twice because two agents both saw it as
  `ready`.

---

## Implementation checklist

As of the initial wiring for this repo:

- [ ] Deploy `beads-rust` via the repo-managed wrapper package
- [ ] `beads-rust init` at repo root; add SQLite files to `.gitignore`
- [x] Commit `.beads/issues.jsonl` (initially empty)
- [ ] Migrate any existing markdown items or start fresh if queues are empty
- [x] Update `docs/tooling-work-items/START-HERE.md` to reference `beads-rust ready` (with README fallback when the CLI is absent)
- [x] Update `docs/router-work-items/START-HERE.md` similarly
- [x] Update `agent-prompts.md` in each queue folder
- [ ] (Optional) Install `bv` and validate `--robot-triage` output
- [ ] Update this document to `Status: Done`
