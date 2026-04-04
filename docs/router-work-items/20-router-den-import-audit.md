# Router Den Import Audit

Status: `ready`
Priority: `medium`
Branch: `docs/router-den-import-audit`

## Goal

Produce a precise map of which router files are still authoritative for the
active den outputs and which ones are now only legacy helpers.

## Why

`den/hosts/router/default.nix` and `den/hosts/router-backup/default.nix` still
pull in a mix of:

- den aspects
- legacy host-local files
- user host overlays

That makes it easy to patch the wrong file first, especially for agents.

## Deliverable

One documentation-focused PR that adds a short source-of-truth map for:

- router
- router-backup

The map should identify, for each major concern, the active file(s):

- hardware
- networking
- Caddy / ingress
- shared router role
- user host overlays
- den aspects

## Suggested Output

Add or update one doc under `docs/` or `den/README.md` with:

- current import graph summary
- which legacy files are still active
- which files are legacy-only / migration candidates
- explicit guidance for where new fixes should land first

## Constraints

- no behavior changes
- no large refactor in this PR
- optimize for navigation clarity, not architectural perfection

## Validation

- verify the documented import graph matches `den/hosts/router*.nix`
- verify the doc names the current active router role and Caddy paths correctly
