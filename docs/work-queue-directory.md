# Work Queue Directory

This file is the cross-repo navigation aid for work-queue documents in the
flakes workspace.

Use it when you know a task belongs to "some repo queue" but do not yet know the
right repository or entry path.

## Authority Rule

Prefer the queue docs that live inside the target repository.

This directory is for discoverability and cross-repo navigation.
It is not meant to replace repo-local queue ownership rules or rankings.

When a target repo has both:

- a `START-HERE.md`
- and a queue `README.md`

use them as:

- `START-HERE.md` for onboarding and claiming rules
- `README.md` for the ranked queue or status index

## Queue Entry Points

| Repository | Scope | Start here | Ranked queue / index |
|---|---|---|---|
| `unified-nix-configuration` | router follow-up in this repo | [`docs/router-work-items/START-HERE.md`](./router-work-items/START-HERE.md) | [`docs/router-work-items/README.md`](./router-work-items/README.md) |
| `unified-nix-configuration` | repo-tooling follow-up in this repo | [`docs/tooling-work-items/START-HERE.md`](./tooling-work-items/START-HERE.md) | [`docs/tooling-work-items/README.md`](./tooling-work-items/README.md) |
| `nix-router-optimized` | router-flake implementation backlog | [`../nix-router-optimized/docs/work-items/START-HERE.md`](../../nix-router-optimized/docs/work-items/START-HERE.md) | [`../nix-router-optimized/docs/work-items/README.md`](../../nix-router-optimized/docs/work-items/README.md) |
| `nix-attic-infra` | attic / CI / cache infra backlog | [`../nix-attic-infra/docs/work-items/README.md`](../../nix-attic-infra/docs/work-items/README.md) | [`../nix-attic-infra/docs/work-items/README.md`](../../nix-attic-infra/docs/work-items/README.md) |
| `agent-roundtable` | Vaglio / control-plane / design implementation backlog | [`../agent-roundtable/docs/work-items/README.md`](../../agent-roundtable/docs/work-items/README.md) | [`../agent-roundtable/docs/work-items/README.md`](../../agent-roundtable/docs/work-items/README.md) |

## Quick Routing Hints

- If the task is about the extracted router flake, go to `nix-router-optimized`.
- If the task is about the homelab config repo itself, start in
  `unified-nix-configuration`.
- If the task is about Attic, cache plumbing, or Nix CI infra, go to
  `nix-attic-infra`.
- If the task is about Vaglio, hosted control plane, board/lease semantics, or
  multi-agent execution substrate, go to `agent-roundtable`.

## Maintenance Rule

Whenever a repo adds or materially reorganizes its queue docs, update this file
so the collector view remains useful.
