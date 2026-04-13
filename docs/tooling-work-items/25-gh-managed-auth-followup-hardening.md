# 25 GH Managed Auth Follow-Up Hardening

Status: `in-progress`

Suggested branch: `fix/tooling-gh-managed-auth-hardening`

## Goal

Finish the follow-up hardening on the managed GitHub auth path so `gh` does not
silently prefer bad inputs or stale documentation.

## Why

The first `gh` wrapper fix restored working auth, but review feedback surfaced
two concrete edge cases that still need deliberate cleanup:

- existing-but-empty managed token files can block fallback behavior
- some docs still describe `fnox` as the primary source even though the repo is
  moving toward managed token files first

These are small but real correctness issues, and they are easier to fix now
than after more agent CLI wrappers copy the same behavior.

## Scope

- make the `gh` wrapper require non-empty managed token files before exporting
  `GH_TOKEN`
- preserve explicit lower-priority fallback paths when managed files are absent
  or empty
- update related docs/work items to describe managed token files as the primary
  source and `fnox` as fallback
- keep the change narrow to the GitHub auth path

## Non-Goals

- redesigning all secret storage in one PR
- migrating every other agent CLI in the same change
- reintroducing `gh auth login` as the normal workflow

## Validation

- an empty managed token file does not block fallback
- a valid managed token file still makes `gh auth status` succeed
- docs and work-item wording match the implemented precedence
