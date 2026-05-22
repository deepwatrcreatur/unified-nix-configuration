# 36 SSH Agent Identity Loading Hardening

Status: `in-progress`

Suggested branch: `feat/tooling-ssh-agent-identity-hardening`

## Goal

Make the SSH-based Git flow more reliable for interactive shells and agent CLIs
by ensuring the expected SSH identity is discoverable early and consistently,
instead of relying on ad hoc session state.

## Why

The SSH signing migration itself succeeded:

- Git uses `gpg.format = "ssh"`
- commit signing verifies successfully
- GitHub SSH transport works non-interactively

But the current Linux path still leaves room for agent confusion:

- `SSH_AUTH_SOCK` is present
- `ssh-agent` may be running with **no identities loaded**
- agent tooling can misread that as “SSH is broken” even when signing still works

This item should harden the agent/identity-loading path rather than redesign the
signing model again.

## Scope

- Review `modules/home-manager/ssh-agent.nix` and related workstation/user config
  for Linux hosts using the deepwatrcreatur SSH setup.
- Decide on a safe default for making the expected key easier to discover, such
  as:
  - explicit SSH client defaults for the primary identity
  - better `IdentityAgent` / `IdentitiesOnly` / `AddKeysToAgent` behavior where
    appropriate
  - session-safe key loading guidance or automation that does not regress
    security expectations
- Keep the signing path SSH-based; do not revert to GPG.
- Preserve existing working GitHub SSH transport and commit signing behavior.
- Prefer a fix that is usable by agent CLIs, not only by interactive humans.

## Non-Goals

- Replacing the SSH signing modules from items 24/25
- Rotating keys
- Broad redesign of all SSH host aliases or secret handling

## Validation

- On the target host, `ssh-add -l` or the chosen replacement signal clearly shows
  the expected identity state after a normal session start.
- `ssh -T -o BatchMode=yes git@github.com` still succeeds.
- A signed test commit still verifies with `git log --show-signature`.
- The result is documented well enough that future agents can distinguish
  signing-state problems from transport/auth problems.

## Dependencies

- Items 24 and 25 already completed

## Follow-up

- Item 37: SSH/Git doctor command + agent-facing troubleshooting notes
