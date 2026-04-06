# Router Den Migration Boundary

Status: `done`
Priority: `medium`
Branch: `refactor/router-den-boundary`

## Goal

Reduce the hybrid den/legacy split for router hosts so the active source of
truth is easier to follow and future fixes stop landing in the wrong file tree.

## Why

Today `den/hosts/router/default.nix` and
`den/hosts/router-backup/default.nix` still import multiple legacy host-local
files:

- `hosts/nixos/router/{hardware-configuration,networking,caddy,disko,configuration}.nix`
- `hosts/nixos/router-backup/{hardware-configuration,networking,caddy,configuration}.nix`

That works, but it hides which paths are still authoritative and makes the
repository harder for agents to navigate.

## Desired Outcome

- The den leaves clearly own host composition.
- Legacy router files are either:
  - folded into den aspects / host leaves, or
  - explicitly limited to hardware-only imports with the rest moved into den.
- Documentation describes the resulting ownership boundary.

## Suggested Scope

This item is now the umbrella note for the more concrete follow-up tasks:

- `20-router-den-import-audit.md`
- `21-router-leaf-inline-migration.md`
- `22-router-backup-den-parity.md`

Use those files for implementation work. Keep this file as the high-level
problem statement and rationale.

## Constraints

- Do not change router behavior as part of a “cleanup only” refactor.
- Preserve current router and router-backup outputs exactly.
- Keep PRs small enough that review bots and humans can verify the ownership
  change without re-auditing the entire router stack.

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- confirm the active router source-of-truth is easier to follow once the
  follow-up tasks land

## Outcome

- Completed follow-up tasks 20, 21, and 22.
- Produced a source-of-truth map in `den/README.md`.
- Inlined the thin router-backup networking wrapper.
- Added per-import status comments to the router den leaf.
- High-level composition is now clearly driven from the den leaves.

## Notes

This is organizational debt, not an emergency runtime fix. It matters because
recent inference work showed how easy it is to patch a dead legacy path when den
is the real source of truth.
