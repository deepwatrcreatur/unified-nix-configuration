# Git SSH Doctor

Use [`scripts/git-ssh-doctor.sh`](../scripts/git-ssh-doctor.sh) when Git over
SSH, SSH commit signing, or agent identity state looks suspect.

This is the repo's read-only first-pass diagnostic for the current SSH signing
model.

## Quick Start

From the repo root:

```bash
bash ./scripts/git-ssh-doctor.sh
```

If you want to avoid the live GitHub SSH probe:

```bash
bash ./scripts/git-ssh-doctor.sh --no-github-probe
```

If you only want config and transport checks without inspecting the latest
commit signature:

```bash
bash ./scripts/git-ssh-doctor.sh --no-git-log
```

## What It Checks

- `gpg.format`, `commit.gpgsign`, `tag.gpgsign`, and `user.signingkey`
- `gpg.ssh.allowedSignersFile` configuration and file presence
- `SSH_AUTH_SOCK` presence and socket state
- `ssh-add -l` identity-loading state
- effective `ssh -G github.com` identity settings
- GitHub SSH transport via `ssh -T -o BatchMode=yes git@github.com`
- latest-commit signature verification via `git log -1 --show-signature`

## How To Read It

### 1. Signing configuration failure

Typical signal:

- `FAIL signing-config`

Meaning:

- Git is not configured for SSH signing in this checkout or host profile.

Likely causes:

- the host/user is missing the SSH signing Home Manager module imports
- local repo config overrides the expected global settings

### 2. Allowed signers failure

Typical signal:

- `FAIL allowed-signers`

Meaning:

- Git is configured for SSH signing, but local signature verification cannot
  confirm signatures because the allowed signers file is missing or unset.

Likely causes:

- Home Manager activation did not write `~/.config/git/allowed_signers`
- the SSH public key path changed or is missing

### 3. SSH agent identity-loading failure

Typical signals:

- `PASS signing-config`
- `PASS auth-sock`
- `WARN ssh-add` or `FAIL ssh-add`

Meaning:

- signing config may be fine, but the current session is not talking to a
  useful SSH agent, or the agent has no identities loaded

Important distinction:

- this does **not** automatically mean SSH signing is broken
- it often means the session/agent path is wrong, the agent is empty, or the
  runtime socket is stale

### 4. GitHub transport/auth failure

Typical signal:

- `FAIL github-probe`

Meaning:

- GitHub SSH auth/transport is failing independently of local signing config

Likely causes:

- no usable SSH identity loaded for transport
- wrong identity selected for `github.com`
- network or firewall interference
- account-side GitHub key registration drift

### 5. Local OpenSSH runtime/config warning

Typical signal:

- `WARN ssh-config`

Meaning:

- the host runtime has an OpenSSH config-read problem, but the doctor is
  explicitly separating that from Git signing configuration

Examples:

- bad permissions on a system OpenSSH include
- unreadable `~/.ssh/config`

## Recommended Triage Order

1. Run `bash ./scripts/git-ssh-doctor.sh`.
2. Fix `FAIL signing-config` before debugging GitHub transport.
3. Fix `FAIL allowed-signers` before trusting local signature-verification
   output.
4. If signing config passes but `ssh-add` fails, treat that as an agent/runtime
   problem, not an automatic reason to revert SSH signing.
5. Only treat `FAIL github-probe` as a GitHub transport issue after the
   signing-config and agent-state lines are understood.

## Current Repo Intent

This repo intentionally uses SSH signing, not GPG signing, for Git commits.
Do not treat incidental `ssh-agent` trouble as evidence that the signing model
should be reverted.
