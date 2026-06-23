# 38 Herdr Packaging And Workstation Landing

Status: `ready`
Suggested branch: `feat/herdr-packaging`
Priority: `high`

## Goal

Add `herdr` to this repo as a first-class repo-managed tool, preferably by
consuming the upstream `herdr` flake on a pinned release tag, and land it on
`workstation` in the same style as other repo-managed agent tooling.

## Why

- `herdr` is not currently installed from this repo.
- Upstream now publishes a Nix flake, so the initial landing should build on
  that instead of assuming a repo-local derivation first.
- The user expects `herdr` to be the next tool surfaced after the recent
  `dmux` landing.
- Another agent should be able to pick this up without blocking ongoing
  `26.05` migration work.

## Scope

1. Use the upstream `herdr` flake published by the project as the default
   package source, pinned to a release tag unless there is a concrete reason
   not to.
2. Add `herdr` as an explicit flake input and plumb the package through the
   repo in the narrowest way that fits existing patterns.
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
- The resulting integration pins `herdr` to a deliberate upstream release tag
  or clearly documents why it does not.
- Any new module or package path is documented enough that another agent can
  extend it later.

## Notes

- Keep this PR narrowly about getting `herdr` available from the upstream flake
  and installed in the workstation config.
- Upstream install docs as of June 22, 2026 recommend release-tagged Nix usage
  like `nix run github:ogulcancelik/herdr/v0.x.y`; mirror that preference in
  the repo unless there is a strong reason to track `master`.
- Follow-up storage/workflow hardening belongs in work item 39.
