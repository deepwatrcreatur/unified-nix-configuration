# 39 Herdr State Layout And Btrfs Subvolume Follow-Up

Status: `ready`
Suggested branch: `design/herdr-state-layout`
Priority: `medium`

## Goal

Define and, if small enough, land the filesystem/state layout that `herdr`
should use when managing agent work areas, with explicit attention to Btrfs
subvolumes and the repo's linked-worktree workflow.

## Why

- The user explicitly called out Btrfs-subvolume measures as part of the
  intended post-`dmux` direction.
- `dmux` already enforces a first-slice worktree guard, but the repo does not
  yet document or codify the matching storage model for the next tool.
- Separating this from packaging keeps the first `herdr` PR small and lets a
  second agent work in parallel.

## Scope

1. Document the intended `herdr` state/worktree model:
   - where ephemeral work areas should live
   - when linked git worktrees are sufficient
   - when Btrfs subvolumes are desirable
   - what cleanup/rollback expectations exist
2. Inspect current repo documentation around worktrees, `dmux`, and Btrfs to
   avoid contradicting established workflow.
3. If there is a small safe implementation slice, add only the minimal support
   needed now:
   - helper docs
   - path defaults
   - preflight checks
   - lightweight wrapper behavior
4. Leave larger host-storage provisioning or migration steps as follow-up items
   if they are not PR-sized.

## Non-Goals

- Repartitioning disks or changing live host storage layouts in this work item.
- Broadly changing Snapper, disko, or backup policy.
- Replacing the current `dmux` linked-worktree guard.

## Validation

- The resulting docs clearly tell another agent where `herdr` state should
  live and why.
- Any code change evaluates cleanly on `workstation`.
- The final shape is consistent with the existing linked-worktree workflow and
  does not require unsafe live storage changes as a hidden prerequisite.

## Notes

- This item should usually start after work item 38 has identified the actual
  `herdr` package shape.
- Prefer documenting the operating model before adding clever automation.
