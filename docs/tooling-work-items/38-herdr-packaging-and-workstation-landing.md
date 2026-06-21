# 38 Herdr Packaging And Workstation Landing

Status: `ready`
Suggested branch: `feat/herdr-packaging`
Priority: `high`

## Goal

Add `herdr` to this repo as a first-class packaged tool and land it on
`workstation` in the same style as other repo-managed agent tooling.

## Why

- `herdr` is not currently installed from this repo.
- The user expects `herdr` to be the next tool surfaced after the recent
  `dmux` landing.
- Another agent should be able to pick this up without blocking ongoing
  `26.05` migration work.

## Scope

1. Confirm the intended upstream source for `herdr` from existing local
   context or the human if it is still ambiguous.
2. Add a repo-local package for `herdr` under `pkgs/` or consume it from an
   explicit flake input if that is the established upstream shape.
3. Expose `herdr` via a narrow Home Manager or system module, following the
   existing repo pattern for agent tools.
4. Enable it on `workstation`.
5. Validate that `herdr` is on PATH after the resulting configuration build.

## Non-Goals

- Designing the full persistent state model for `herdr`.
- Reworking the entire `dmux` workflow again.
- Deploying `herdr` broadly across the fleet in the same PR.

## Validation

- `nix eval .#nixosConfigurations.workstation.config.system.build.toplevel.drvPath --raw`
  succeeds.
- A `workstation` build or switch path includes `herdr`.
- `command -v herdr` succeeds on `workstation` after landing.
- Any new module or package path is documented enough that another agent can
  extend it later.

## Notes

- Keep this PR narrowly about getting `herdr` packaged and available.
- If the upstream source is unclear, stop and ask for the exact repo instead of
  guessing.
- Follow-up storage/workflow hardening belongs in work item 39.
