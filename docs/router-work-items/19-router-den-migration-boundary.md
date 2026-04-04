# Router Den Migration Boundary

Status: `ready`
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

Do this in one reviewable PR only if the split stays small. Otherwise, break it
into follow-up tasks.

Good first target:

- move non-hardware composition out of `den/hosts/router*.nix` legacy imports
- keep `hardware-configuration.nix` as the last host-local import if needed
- decide whether `networking.nix`, `caddy.nix`, and `configuration.nix` should
  become:
  - den aspects, or
  - inlined host-leaf imports inside `den/hosts/router*.nix`

## Constraints

- Do not change router behavior as part of a “cleanup only” refactor.
- Preserve current router and router-backup outputs exactly.
- Keep PRs small enough that review bots and humans can verify the ownership
  change without re-auditing the entire router stack.

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- confirm `den/hosts/router*.nix` import graph is simpler after the change

## Notes

This is organizational debt, not an emergency runtime fix. It matters because
recent inference work showed how easy it is to patch a dead legacy path when den
is the real source of truth.
