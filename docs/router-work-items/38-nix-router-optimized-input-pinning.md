# 38 nix-router-optimized Flake Input Pinning

Status: `ready`
Suggested branch: `fix/nix-router-optimized-input-pinning`
Priority: `medium`

## Goal

Pin `nix-router-optimized` as a locked flake input in the main nix-config repo
so that changes to it require an explicit `nix flake update` step and a
successful build before they reach the live router.

## Why

The 2026-04-23 regression included a `localAddress` change (commit `65a57b4` in
`nix-router-optimized`) that silently made the HA listener unreachable to peers.
The main nix-config repo was consuming `nix-router-optimized` in a way that
allowed this change to arrive without a forced review step.

Pinned inputs require a conscious `nix flake update nix-router-optimized` +
rebuild before any upstream change reaches production. This mirrors the policy
in `docs/upstream-hotfix-policy.md` but applies it specifically to the
router-infrastructure subflake.

## Scope

### 1. Verify current input lock state

```bash
cd unified-nix-configuration
nix flake metadata --json | jq '.locks.nodes."nix-router-optimized"'
```

If the input resolves to a branch ref (`ref = "main"`) without a locked hash,
changes to the branch arrive immediately on the next `nix flake update`. If a
hash is already locked, confirm that the lock is being committed and not
`.gitignore`d.

### 2. Pin to a specific commit

After the HA deployment work (item 37) is complete and source changes are
merged into `nix-router-optimized`:

```bash
# Lock to the verified post-fix commit
nix flake update nix-router-optimized   # pulls latest; check the new hash
git add flake.lock
git commit -m "chore: pin nix-router-optimized to post-HA-fix commit"
```

From this point forward, updating `nix-router-optimized` is a deliberate
two-step: `nix flake update nix-router-optimized` then build + test before
committing the new lock.

### 3. Document the update workflow

Add a note to `docs/ops.md` (or the existing `docs/upstream-hotfix-policy.md`)
describing the intended update cadence for `nix-router-optimized`:

- Routine updates: batched with a `nix flake update` run, build-tested, PR'd
- Security/critical fixes: update only `nix-router-optimized` input,
  build-tested, fast-track PR

### 4. Consider a CI check

If the repo has a CI pipeline (`outputs/checks.nix`), add a check that fails if
`flake.lock` is not committed (i.e., the lock is present in `.gitignore` or
missing from the repo). This prevents future silent drift.

## Non-Goals

- Pinning all flake inputs (broader scope, separate conversation)
- Changing how `nix-router-optimized` itself is developed

## Validation

- `nix flake metadata` shows a locked hash for `nix-router-optimized`, not a
  floating branch ref
- A deliberate `nix flake update nix-router-optimized` is the only way to pull
  new changes from it
- `flake.lock` is committed in git and up to date

## Dependencies

- Item 37 (HA pair deployment) — pin to a commit that includes the verified
  post-fix state, not a partially-applied state
