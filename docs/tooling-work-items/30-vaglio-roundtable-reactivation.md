# 30 Vaglio Roundtable Reactivation

Status: `in-progress`
Suggested branch: `feat/vaglio-roundtable-reactivation`
Priority: `high`

## Goal

Restore the Roundtable service as an active host feature on `vaglio`, so the
 repo once again has a concrete deployment target for `roundtable.deepwatercreature.com`.

## Why

- The `homeserver-roundtable` aspect exists, but it was silently omitted at
  eval time because its required secret was missing from the repo source.
- The repo currently lacks both of the concrete prerequisites needed to make
  that reattachment real:
  - `ssh-keys/agenix-machine-identities/vaglio.pub` does not exist
  - `secrets-agenix/roundtable-secret-key-base.age` does not exist
- Any Forgejo-shell demo or code-analysis UI work is blocked until there is a
  real Roundtable host path again.

## Scope

1. Provision or document the required agenix secret inputs for Roundtable,
   especially `roundtable-secret-key-base.age` and the `vaglio` machine
   identity public key.
2. Create or recover the actual `vaglio` Proxmox LXC guest so there is a real
   host to administer with `pct enter`.
3. Reattach the `homeserver-roundtable` aspect to `vaglio` in inventory.
4. Ensure the host evaluates cleanly in this repo with the Roundtable aspect
   active again.
5. Add a short note describing why `vaglio` is the chosen Roundtable host.

## Non-Goals

- Designing the Forgejo-shell feature itself
- Building the code-analysis demo UI
- Reworking OIDC or ingress architecture beyond what is needed to reactivate
  the existing Roundtable service

## Validation

- `nix eval .#nixosConfigurations.vaglio.config.system.build.toplevel.drvPath`
  succeeds with Roundtable reattached
- Proxmox cluster config contains a real `vaglio` LXC definition that can be
  entered with `pct enter`
- the required Roundtable secrets are explicit and no longer hidden behind
  silent config omission
- `roundtable.deepwatercreature.com` is once again backed by an active host
  configuration path in this repo

## Notes

This item exists because deployment reality needs to be restored before the
demo-oriented Forgejo-shell work can be made credible.

Current progress as of May 10, 2026:

- PR #143 (`fix/vaglio-forgejo-shell`) restores the missing
  `roundtable-secret-key-base.age`, adds
  `ssh-keys/agenix-machine-identities/vaglio.pub`, and bumps the pinned
  `agent-roundtable` revision to one that contains the Forgejo-shell route.
- With that branch checked out, both of these evals succeed:
  - `nix eval .#nixosConfigurations.vaglio.config.services.roundtable.enable`
  - `nix eval .#nixosConfigurations.homeserver.config.services.roundtable.enable`
- PR #143 later merged those repo-side prerequisites.
- PR #147 later fixed the `agent-roundtable` flake input on `main`, and
  `agent-roundtable` PR #85 fixed the standalone runtime issues upstream.
- The remaining blocker is now item 36:
  `vaglio` still hangs during live `26.05` -> repo `25.11` activation, even
  after preserving the legacy DHCP stack for the landing attempt.
