# Agent Handoff Plan

Date: 2026-04-02

## Current repo state

- Repository: `unified-nix-configuration`
- Current local branch during this session: `refactor/den-inventory-aspects`
- Work completed in this repo during the immediately preceding sessions:
  - router / router-backup cleanup and management-IP model
  - router dashboard PRs and structural follow-up PRs
  - den/aspect follow-up PRs
  - desktop session / keyring cleanup

This handoff file is specifically for the latest upstream work on Attic-related flakes and the likely follow-up work in this repo.

## Upstream PRs opened

### nix-attic-infra

- PR: <https://github.com/deepwatrcreatur/nix-attic-infra/pull/9>
- Branch: `ci/expand-flake-evaluation-checks`
- Commit: `19a210c`

Summary:
- replaces the shallow flake module-import check with representative NixOS and Home Manager evaluations
- adds `home-manager` as a flake input so shipped HM modules are actually exercised in CI
- fixes a dormant issue in `modules/home-manager/attic-client-darwin.nix` that the stronger evaluation surfaced

Validation already run:
- `nix flake check --no-build /tmp/nix-attic-infra`
- `nix build /tmp/nix-attic-infra#checks.x86_64-linux.home-manager-attic-client-darwin-eval`

### attic-observatory

- PR: <https://github.com/deepwatrcreatur/attic-observatory/pull/6>
- Branch: `ci/add-flake-checks-and-app`
- Commit: `324822b`

Summary:
- adds flake-level unit test checks around the existing Python test suite
- adds `apps.default` so the dashboard can be launched with `nix run`
- adds a small dev shell and updates README workflow docs

Validation already run:
- `nix flake check --no-build /tmp/attic-observatory`
- `nix build /tmp/attic-observatory#checks.x86_64-linux.unit-tests`

## Most useful next work in this repo

Do this after PR #9 for `nix-attic-infra` merges and `flake.lock` is updated:

1. Refactor local Home Manager attic client support to wrap upstream instead of reimplementing it.

Current local file to replace or thin out:
- [`modules/home-manager/common/attic-client.nix`](../modules/home-manager/common/attic-client.nix)

Why:
- it still has older portability/correctness issues that upstream now handles better:
  - unquoted TOML server keys
  - GNU `sed -i`
  - weak hardcoded shell aliases

Target shape:
- import `inputs.nix-attic-infra.homeManagerModules.attic-client`
- keep only repo-specific defaults and overlays locally
- preserve any desired `fnox` token fallback only if still needed

2. Consider replacing local Darwin attic shim with an upstream wrapper.

Current local file:
- [`modules/home-manager/attic-client-darwin.nix`](../modules/home-manager/attic-client-darwin.nix)

Likely action:
- replace with a compatibility shim importing `inputs.nix-attic-infra.homeManagerModules.attic-client-darwin`
- or delete if no local path compatibility is required

3. Refresh `flake.lock` once upstream PRs merge.

Commands:
```fish
cd ~/flakes/unified-nix-configuration
nix flake lock --update-input nix-attic-infra
```

Optional once `attic-observatory` PR merges:
```fish
nix flake lock --update-input nix-attic-infra
```

Note:
- `attic-observatory` is pulled transitively by `nix-attic-infra`, so the important lock update here is still the `nix-attic-infra` input.

## Repo-local attic module status

Already in good shape:
- [`modules/nixos/attic-observatory.nix`](../modules/nixos/attic-observatory.nix)
- [`modules/nixos/attic-post-build-hook.nix`](../modules/nixos/attic-post-build-hook.nix)

These are already compatibility shims importing upstream implementation.

Not yet upstream-backed:
- [`modules/home-manager/common/attic-client.nix`](../modules/home-manager/common/attic-client.nix)
- [`modules/home-manager/attic-client-darwin.nix`](../modules/home-manager/attic-client-darwin.nix)

## Good validation commands for the follow-up refactor

After switching this repo to consume the improved upstream HM modules:

```fish
nix flake check --no-build
nix build .#homeConfigurations.root@attic-cache.activationPackage
nix build .#darwinConfigurations.macminim4.system
```

If those exact outputs fail for unrelated existing reasons, at minimum evaluate the relevant module paths and the host(s) that consume attic HM config.

## Operational note

When pushing to GitHub from this host, plain `git push` may fail because `~/.ssh/config` permissions are broken.

Working fallback used successfully in this session:
```fish
GIT_SSH_COMMAND='ssh -F /dev/null' git -C /tmp/<repo> push origin <branch>
```

`gh pr create` may also need escalated/network-enabled execution in this environment.

## Router follow-up

Once `router` is back in a known-good booting and routing state, use:
- [`docs/router-hardening-plan.md`](./router-hardening-plan.md)

That document captures:
- the most useful router-specific ideas to borrow from existing Nix router work
- the target fault-tolerance model
- separate branch/PR tracks that other agents can pick up in parallel
