# 31 Forgejo-Shell Demo Surface On Vaglio

Status: `ready`
Suggested branch: `feat/forgejo-shell-vaglio-surface`
Priority: `high`

## Goal

Expose a working `forgejo-shell` demo surface at
`roundtable.deepwatercreature.com/forgejo-shell`, hosted on `vaglio`.

## Why

- The user was told to expect a visible Forgejo-shell surface soon, but the
  route is not yet deployed on the active Vaglio host.
- A concrete route and service boundary are needed before higher-level demo
  analysis work can be shown to other people.
- This should be a visible, inspectable deployment step, not just internal
  package plumbing.

## Scope

1. Decide the minimal deploy shape for `forgejo-shell` on `vaglio`:
   - standalone app/service, or
   - a narrowly scoped component behind Roundtable, or
   - a thin shell around a Forgejo-derived service path
2. Add the NixOS service/plumbing needed for that minimal shape.
3. Add ingress/routing so `/forgejo-shell` resolves on
   `roundtable.deepwatercreature.com`.
4. Document the expected runtime dependencies and any placeholder auth model.

## Non-Goals

- Full Forgejo productization
- JJ integration inside Forgejo internals
- The full public-repo stress-analysis demo

## Validation

- `vaglio` evaluates cleanly with the new service and route
- `/forgejo-shell` is represented explicitly in repo config, not implied by
  chat history
- a human can tell from the repo where the service starts, how it is routed,
  and what runtime secrets or packages it needs

## Notes

Keep this item narrowly about getting a visible service path up. If deep app
design questions appear, leave those to follow-up items instead of ballooning
this PR.

Dependency note:

- PR #143 restores the repo-side prerequisites and the upstream app revision
  that contains `/forgejo-shell`, but it does not by itself deploy a working
  surface on the live host.
- Treat item 30 and item 35 as prerequisites for actually making the demo path
  visible and stable.
