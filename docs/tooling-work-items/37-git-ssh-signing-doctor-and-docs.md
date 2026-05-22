# 37 Git SSH Signing Doctor and Troubleshooting Notes

Status: `ready`

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

- None, though it pairs well with item 36
