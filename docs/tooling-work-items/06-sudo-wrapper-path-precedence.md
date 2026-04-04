# 06 Sudo Wrapper Path Precedence

Status: `in-progress`

Suggested branch: `fix/tooling-sudo-wrapper-path`

## Goal

Make `sudo` resolve to `/run/wrappers/bin/sudo` reliably on NixOS hosts,
including non-interactive execution paths used by `nixos-rebuild`, SSH command
execution, and agent automation.

## Why This Exists

On `inference1`, `sudo` currently resolves to
`/run/current-system/sw/bin/sudo`, while the working setuid wrapper is
`/run/wrappers/bin/sudo`. That breaks operational commands in exactly the
contexts where shell aliases are not applied.

The short-term workaround is to call `/run/wrappers/bin/sudo` explicitly. This
work item is about making that workaround unnecessary, or at least documenting
the remaining edge cases precisely.

## Scope

- audit how PATH is assembled for interactive shells, non-interactive shells,
  SSH remote commands, Home Manager shells, and system-level command runners
- identify why `/run/current-system/sw/bin` is winning over `/run/wrappers/bin`
  on affected hosts
- implement the smallest reliable fix that improves default command resolution
  without breaking current shell behavior on workstation-class systems
- keep explicit-path usage for truly critical operational docs if that remains
  the safer invariant
- add comments explaining why aliases are insufficient for `sudo`

## Non-Goals

- replacing `sudo` with a wrapper alias only
- redesigning privilege escalation across the repo
- changing unrelated PATH ordering just for stylistic consistency

## Validation

- on at least one affected NixOS VM, `command -v sudo` resolves to the working
  wrapper path in the execution contexts that matter for rebuilds
- `sudo -n true` succeeds where it already should
- repo docs clearly state when `/run/wrappers/bin/sudo` must still be used
- comments make it obvious why future agents should not "simplify" this back to
  an alias-only fix
