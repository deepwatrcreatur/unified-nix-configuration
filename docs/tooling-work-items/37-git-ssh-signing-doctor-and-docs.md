# 37 Git SSH Signing Doctor and Troubleshooting Notes

Status: `done`

Suggested branch: `feat/tooling-git-ssh-doctor`

## Goal

Add a small, repeatable troubleshooting surface for Git-over-SSH and SSH commit
signing so agents and humans can quickly answer:

- is signing configured
- is signing actually working
- is SSH transport to GitHub working
- is the SSH agent empty

## Why

Recent inspection showed that these are distinct states:

- SSH commit signing can work
- GitHub SSH transport can work
- while `ssh-agent` still reports no loaded identities

That distinction is easy for humans to miss and easy for agents to misdiagnose.
A single quick doctor flow would reduce repeated confusion.

## Scope

- Add a lightweight doctor command, script, or documented probe sequence for:
  - `git config` signing fields
  - allowed signers presence
  - SSH agent socket presence
  - loaded identity state
  - GitHub SSH transport probe
  - signed-commit verification probe
- Update repo docs and agent-facing guidance to distinguish:
  - SSH signing configuration failures
  - SSH agent identity-loading failures
  - GitHub transport/auth failures
- Prefer a read-only diagnostic by default.
- If a helper script is added, keep it narrow and text-oriented so agents can use
  it easily.

## Non-Goals

- Full SSH configuration redesign
- Host deployment unrelated to Git/SSH flow
- Replacing normal Git commands with wrappers everywhere

## Validation

- A human or agent can run one documented flow and classify the problem
  correctly.
- The docs no longer imply that “SSH trouble” is automatically a signing failure.
- The diagnostic surface works on the workstation path that currently uses the
  SSH signing modules.

## Dependencies

- None, though it pairs well with
  [36 SSH Agent Identity Loading Hardening](./36-ssh-agent-identity-loading-hardening.md)

## Outcome

- Added a read-only repo-local doctor script at
  [`scripts/git-ssh-doctor.sh`](../../scripts/git-ssh-doctor.sh).
- Added usage and interpretation notes at
  [`docs/git-ssh-doctor.md`](../git-ssh-doctor.md).
- Updated [`scripts/README.md`](../../scripts/README.md) so the doctor is
  discoverable from the existing script index.
- Updated [`AGENTS.md`](../../AGENTS.md) and [`agents.md`](../../agents.md) so
  the repo no longer implies that SSH signing failures, empty `ssh-agent`
  state, and GitHub transport problems are the same class of issue.
- Validated on `workstation` against the live environment:
  - Git SSH signing config is present
  - `allowed_signers` exists
  - `ssh-agent` has the expected ED25519 identity loaded
  - `ssh -T -o BatchMode=yes git@github.com` succeeds
  - the remaining warning on `HEAD` is about an older GPG-signed merge commit
    whose public verification key is not available locally, which is distinct
    from SSH signing or GitHub transport failure
