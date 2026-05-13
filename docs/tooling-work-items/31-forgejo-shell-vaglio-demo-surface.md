# 31 Forgejo-Shell Demo Surface On Vaglio

Status: `done`
Suggested branch: `feat/forgejo-shell-vaglio-surface`
Priority: `high`

## Goal

Expose a working `forgejo-shell` demo surface at
`roundtable.deepwatercreature.com/forgejo-shell`, hosted on `vaglio`.

## Why

- The user was told to expect a visible Forgejo-shell surface soon, and this
  item tracks making that surface real on the active Vaglio host.
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

## Outcome

Completed on May 13, 2026.

- `https://roundtable.deepwatercreature.com/forgejo-shell` now returns
  `HTTP/2 200` publicly through the router Caddy proxy.
- The live route is backed by the Roundtable app on `vaglio`, including the
  `ForgejoShellLive` route in the upstream `agent-roundtable` repo.
- The public surface is live even though the inventory-backed Roundtable
  reattachment in this repo remains a separate follow-up.

## Notes

Keep this item narrowly about getting a visible service path up. If deep app
design questions appear, leave those to follow-up items instead of ballooning
this PR.

Dependency note:

- PR #143 restored the repo-side prerequisites and the upstream app revision
  that contains `/forgejo-shell`.
- Agent-roundtable PR #85 fixed the standalone runtime issues upstream.
- The live `vaglio` host is now landed on the repo `25.11` baseline, and
  `http://127.0.0.1:4000/forgejo-shell` returns `200`.
- Follow-up demo work should build on this working route rather than treating
  the surface itself as still blocked.
- Item 35 provided the standalone-service hardening needed to keep the live
  Vaglio deployment stable.
- Item 30 remains the follow-up for restoring the inventory-backed Roundtable
  host path in this repo.
