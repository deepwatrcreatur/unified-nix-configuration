# Git SSH Doctor

Use the repo-local doctor when Git SSH transport, SSH commit signing, and
`ssh-agent` state start looking mixed together.

```bash
./scripts/git-ssh-doctor.sh
```

To inspect a specific commit or ref instead of `HEAD` for the signature probe:

```bash
./scripts/git-ssh-doctor.sh <rev>
```

The script is read-only by default. It classifies four different failure modes
that are easy to conflate:

- signing config failure
- agent identity-loading failure
- GitHub transport/auth failure
- signature verification mismatch

## What It Checks

The doctor runs a single probe sequence for:

- `git config` signing fields
- `gpg.ssh.allowedSignersFile` presence and first entry
- `SSH_AUTH_SOCK` presence and socket type
- `ssh-add -l` identity state
- `ssh -T -o BatchMode=yes git@github.com` transport/auth reachability
- `git log --show-signature -n 1 HEAD` verification behavior

## How To Read The Result

### Signing config failure

Typical signs:

- `gpg.format` is not `ssh`
- `user.signingkey` is unset or points at a missing file
- `gpg.ssh.allowedSignersFile` is unset or missing

This means Git is not configured correctly for SSH signing, regardless of
whether GitHub SSH transport works.

### Agent identity-loading failure

Typical signs:

- `SSH_AUTH_SOCK` exists
- the socket is present
- `ssh-add -l` reports no identities or cannot talk to the agent

This is distinct from signing config. SSH signing can still verify locally if
Git is pointed at the signing key file and `allowed_signers` is present.

### GitHub transport/auth failure

Typical signs:

- the GitHub SSH probe fails
- `ssh-add -l` may or may not show identities
- signing config may still be correct

This means repository transport/auth is broken even if local signing
verification works.

### Signature verification mismatch

Typical signs from `git log --show-signature`:

- `No signature`
- `Can't check signature: No public key`
- another signature result that is not clearly successful

This is about the commit being inspected and the local verification context. It
does not automatically imply an SSH transport problem or an empty `ssh-agent`.

## Workstation Notes

On the `workstation` path in this repo:

- Git SSH signing is configured by
  [`modules/home-manager/git-ssh-signing.nix`](../modules/home-manager/git-ssh-signing.nix)
- the agent socket path and GitHub identity defaults come from
  [`modules/home-manager/ssh-agent.nix`](../modules/home-manager/ssh-agent.nix)

That means a healthy configuration can still produce these mixed states:

- `gpg.format = ssh`
- `allowed_signers` exists
- GitHub transport works
- while `ssh-add -l` still reports no loaded identities

That is exactly why this doctor exists.
