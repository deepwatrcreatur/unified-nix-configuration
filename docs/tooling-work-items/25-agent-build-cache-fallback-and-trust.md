# 25 Agent Build Cache Fallback And Trust

Status: `done`

Suggested branch: `fix/tooling-agent-build-cache-fallback`

## Goal

Make agent-driven Nix builds degrade predictably when the local `attic-cache`
or optional public caches are unavailable, misaddressed, or not trusted by the
current key set.

## Why

Recent agent builds show several concrete failure modes:

- `attic-cache` may be unreachable because the router/DHCP state is wrong or a
  host moved to a different address
- public substitutes are ignored because their signing keys are not in
  `trusted-public-keys`
- agents still try to build through the default substituter set and get noisy,
  slow, or misleading failures

The repo needs a deliberate policy for how agent builds should choose, trust,
and fall back from substituters.

## Scope

- audit where substituters and trusted keys are defined for the relevant hosts
  and users
- decide which caches are first-class, optional, or intentionally excluded for
  agent workflows
- add a documented and reproducible fallback path for agent builds when
  `attic-cache` is unavailable
- ensure warnings about untrusted public caches are either resolved or stopped
  by configuration, rather than left as ambient noise
- document the expected emergency path while the router or cache host is
  degraded

## Non-Goals

- fixing the router DHCP issue itself in this PR
- onboarding every third-party public cache casually
- turning this into a broad binary-cache architecture redesign

## Validation

- agent builds can be run with a known-good substituter set even when
  `attic-cache` is down
- configured public caches are either trusted correctly or not queried
- docs make the degraded-mode build path obvious to future agents

## Notes

This is the tooling-side counterpart to the router-side lease/cutover work.
The router items fix why `attic-cache` moved; this item fixes how agents behave
when that still happens.

## Current implementation state

- Active branch: `fix/tooling-agent-build-cache-fallback`
- Worktree: `/tmp/unified-build-cache-fallback`
- PR: #100 (`fix(tooling): align cache trust and fallback behavior`)
- CI: inventory/module/security checks passing; GitHub reports `mergeable_state = dirty` (needs rebase/refresh against `main`).

## Next actions

- Rebase `fix/tooling-agent-build-cache-fallback` onto `main` and resolve conflicts.
- Re-run inventory/module checks locally after conflict resolution.
- If CI remains green and local checks pass, merge PR #100 and then flip this item to `done`.
