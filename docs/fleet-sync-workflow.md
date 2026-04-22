# Fleet Sync Workflow with repo_updater (ru)

`ru` keeps every repo under `~/flakes/` in sync with a single command and
gives agents a structured view of pending work across the fleet.

## Quick Reference

| Command | What it does |
|---------|-------------|
| `ru sync` | Pull updates for all repos; clone any that are missing |
| `ru status` | Show branch drift and dirty worktrees without touching anything |
| `ru status --json` | Machine-readable status for agent pipelines |
| `ru list` | Show the repos `ru` knows about |
| `ru add owner/repo` | Register a new GitHub repo |
| `ru review` | AI-assisted review triage across all repos |
| `ru prune` | Find local repos not in your config |
| `ru doctor` | System diagnostics (checks git, gh, gum, jq) |

## Configuration

`ru` is configured via home-manager (`programs.repo-updater.enable = true`)
on the workstation host.  The generated config lives at:

```
~/.config/ru/config        ← PROJECTS_DIR and LAYOUT
~/.config/ru/repos.d/      ← per-user repo lists (user-managed, not NixOS)
```

`PROJECTS_DIR` is set to `~/flakes/` with `LAYOUT=flat`, matching the
existing convention where every repo sits directly under that directory.

### Adding repos to your list

```bash
# Register repos you want ru to track and clone
ru add deepwatrcreatur/unified-nix-configuration
ru add deepwatrcreatur/nix-router-optimized
ru add deepwatrcreatur/nix-rtk

# Or edit the file directly
$EDITOR ~/.config/ru/repos.d/public.txt
```

Format: one `owner/repo` per line.  Branch override: `owner/repo@my-branch`.

## Common Workflows

### Daily sync

```bash
ru sync
# Exits 0 if everything is clean.
# Exit 2 = conflicts detected — ru prints resolution commands.
# Exit 3 = partial failure — some repos failed; check output.
```

### Fleet status for agents

```bash
ru status --json | jq '.repos[] | select(.status != "clean")'
```

This surfaces repos with uncommitted changes or diverged branches without
making any changes, safe to run in a read-only context.

### Agentic PR review

```bash
ru review
```

Iterates open PRs across all repos and invokes `gh` for context.  Designed
for agent-assisted triage; works well alongside `repo-fleet prs`.

### Checking for uncommitted worktrees before a rebuild

```bash
ru status --no-fetch --json \
  | jq -r '.repos[] | select(.dirty == true) | .path'
```

## Relationship to nix-repo-fleet

`ru` and `nix-repo-fleet` are complementary:

| Tool | Focus |
|------|-------|
| `ru sync` / `ru status` | Git operations — pull, clone, detect drift |
| `repo-fleet repos` | Worktree hygiene summary with JSON contract |
| `repo-fleet prs` | GitHub PR readiness and merge-block analysis |

Run `ru sync` first to ensure repos are up to date, then use `repo-fleet`
to prioritise what to review or merge.

## Protected Repos

Some repos under `~/flakes/` should not be mass-synced because they are
active worktrees or have in-flight rebases:

- Worktree checkouts (e.g. `/tmp/wt-pr*/`) — exclude by keeping them out of
  `~/.config/ru/repos.d/`.
- `unified-nix-configuration` — contains NixOS secrets references; prefer
  explicit `git pull` with deliberate review.

`ru` only manages repos in its config list, so unlisted local directories are
never touched.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All repos clean or successfully updated |
| 1 | Usage / configuration error |
| 2 | One or more repos have merge conflicts |
| 3 | Partial failure (some repos failed) |
| 4 | Interrupted by user |
| 5 | Dependency missing (git, gh, etc.) |
