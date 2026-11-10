# Herdr State Layout and Worktree Model

This document defines the storage, filesystem, and state layout model for `herdr` agent workspaces within the `unified-nix-configuration` ecosystem, detailing the boundary between linked Git worktrees and Btrfs subvolumes.

---

## 1. Context and Problem Statement

`herdr` is the repository-managed agent multiplexer for autonomous coding sessions across workstations (`emerald`, `phoenix`). Multiple agents (Claude Code, Antigravity, Codex, etc.) operate concurrently in distinct sessions.

Unconstrained agent execution presents two primary failure modes:

1. **Shared Checkout Contamination**:
   Running mutating agent harnesses directly inside a primary repository or bare checkout corrupts local branch state, produces uncommitted drift, and disrupts other running harnesses or operator workflows. (This mirrors the problem solved by the `dmux` first-slice guard).

2. **Snapper / Btrfs Snapshot Ballooning**:
   The fleet standardizes on Btrfs with hourly timeline Snapper snapshots configured on `/` and `/home` (`modules/nixos/snapper.nix`). Ephemeral agent activity—such as rapid compilation artifacts, `node_modules`, Nix store derivations, and git churn—can rapidly inflate `/home` snapshot sizes and degrade filesystem performance if stored directly in a standard directory.

---

## 2. Directory Hierarchy and Conventions

The repo establishes the following standard path conventions:

| Path | Purpose | Storage Characteristics |
| :--- | :--- | :--- |
| `~/flakes/<repo>` | Bare Git checkouts (e.g. `~/flakes/unified-nix-configuration`) | Read-mostly object store and central ref repository; **never** use as an agent working directory. |
| `~/flakes-worktrees/<repo>/<branch>` | Linked Git worktrees for PR-scoped feature work | Fast, branch-scoped work areas sharing the parent repo object database. |
| `~/.config/herdr/` | Multiplexer configuration and session history | Persisted in `/home`; contains `config.toml`, `session.json`, and `session-snapshots/`. |
| `~/.local/state/herdr/` | Ephemeral runtime sockets and agent state detection | Managed per-session; excluded from VCS. |
| `~/agent-workspaces/` | High-churn scratchpads and isolated execution sandboxes | Dedicated Btrfs subvolume; completely excluded from parent Snapper timeline snapshots. |

---

## 3. Btrfs Subvolume and Snapper Isolation Mechanics

In Btrfs, a subvolume created inside an existing subvolume (e.g. `btrfs subvolume create ~/agent-workspaces`) is treated as a separate filesystem root.

### Key Invariant:
> **Snapshots are not recursive in Btrfs.**
> When Snapper takes a snapshot of `/home` (`@home`), any nested subvolume (such as `~/agent-workspaces` or a subvolume-mounted `~/flakes-worktrees`) is **excluded** from that snapshot.

### Benefits for Agent Tooling:
- **Zero Snapper Pollution**: High-frequency creation and deletion of files within subvolume-backed workspaces does not accumulate inside `/home` snapshot timelines.
- **Instant Rollback**: Agents executing complex build scripts can take an instant CoW snapshot prior to execution:
  ```bash
  btrfs subvolume snapshot ~/agent-workspaces/task-42 ~/agent-workspaces/task-42-backup
  ```
- **Instant Deletion**: Tearing down a multi-gigabyte workspace subvolume is an atomic metadata operation:
  ```bash
  btrfs subvolume delete ~/agent-workspaces/task-42
  ```

---

## 4. Decision Matrix: Linked Worktrees vs. Btrfs Subvolumes

Agents should select their working directory according to the nature of the task:

| Requirement | Preferred Mechanism | Location | Rationale |
| :--- | :--- | :--- | :--- |
| Standard feature, bugfix, or doc PR | **Linked Git Worktree** | `~/flakes-worktrees/<repo>/<branch>` | Keeps changes scoped to one branch; shares the local `.git` object pool. |
| Deep refactoring or long-running tasks | **Linked Worktree on Subvolume** | `~/flakes-worktrees/<repo>/<branch>` *(on dedicated subvol)* | Combines git branch management with Snapper snapshot exclusion. |
| Untrusted code execution / build spike | **Ephemeral Btrfs Subvolume** | `~/agent-workspaces/<task-id>` | Instant snapshotting before runs; instant atomic rollback or destruction. |
| Read-only inspection / triage | **Any existing worktree** | `~/flakes-worktrees/main` | Zero disk or ref mutation required. |

---

## 5. Worktree Guard and Preflight Policy

To prevent accidents, `herdr` integrations and wrappers follow the same safety rules established in `pkgs/dmux.nix`:

1. **Bare Repository Rejection**:
   If the current working directory is a bare Git repository (`git rev-parse --is-bare-repository` returns `true`), mutating agent commands MUST NOT execute. The agent must create a linked worktree first.
2. **Primary Checkout Protection**:
   If `.git` is a directory (primary checkout) rather than a file containing a `gitdir:` pointer (linked worktree), agents should warn or require explicit override before mutating files.
3. **Preflight Utility (`herdr-preflight`)**:
   A lightweight command provided in `programs.herdr` to check current checkout state and advise on safe worktree creation.

---

## 6. Lifecycle and Cleanup Protocol

1. **Claiming Work**:
   - Check if branch/worktree already exists (`git worktree list`).
   - If not, create worktree:
     ```bash
     git -C ~/flakes/<repo> worktree add ~/flakes-worktrees/<repo>/<branch> -b <branch>
     ```
2. **Finishing Work**:
   - Ensure all changes are committed, pushed, and merged into upstream `main`.
   - Remove the worktree when complete:
     ```bash
     git -C ~/flakes/<repo> worktree remove ~/flakes-worktrees/<repo>/<branch>
     ```
   - Delete any temporary Btrfs subvolumes:
     ```bash
     btrfs subvolume delete ~/agent-workspaces/<task-id>
     ```
