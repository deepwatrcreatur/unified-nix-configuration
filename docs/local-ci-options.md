# Local CI and Caching Options

This document summarizes CI and cache options you can run under your own control, alongside or instead of nix-ci.com.

## 1. nix-ci.com cache

You already have optional integration with nix-ci.com:

- `den/aspects/nix-caches.nix` defines:
  - `myModules.caches.enable` (master switch)
  - `myModules.caches.enableNixCi` (default `true`)
- `modules/common/nix-settings.nix` and `modules/nixos/common/nix-ci-netrc.nix` wire:
  - `substituters += https://cache.nix-ci.com`
  - `nix.settings.netrc-file = /run/nix/nix-ci-netrc`
- Secrets:
  - `secrets-agenix/nix-ci-netrc.age` + agenix

**How to test on a host**

On any machine built from this flake:

```bash
nix show-config | grep cache.nix-ci.com
```

If you see `https://cache.nix-ci.com` in `substituters`, nix-ci is enabled. If not, either the aspect is disabled for that host or credentials are missing.

You can also check:

```bash
systemctl status nix-ci-netrc.service
```

on NixOS hosts using the systemd module.

## 2. Attic cache (self-hosted)

You have a self-hosted Attic setup:

- `lib/attic-cache.nix` defines substituters including:
  - your local `attic-cache` endpoint
  - optional fallback to `cache.nix-ci.com`
- Modules:
  - `modules/nixos/attic-client.nix`, `attic-post-build-hook.nix`, `attic-observatory.nix`
  - Home Manager variants for user-level config
- Secrets and keys are in `secrets-agenix` and `ssh-keys`.

**How to test Attic**

On a host with the Attic client aspect:

```bash
nix show-config | grep attic-cache
```

Build something, then verify it lands in Attic via `attic list` or the observatory.

## 3. Local CI strategies

You can run CI under your own policies, pushing results to Attic (and optionally consuming nix-ci as a read-only cache):

### 3.1 Self-hosted GitHub Actions runner

- Run a GitHub Actions runner on a NixOS homelab host.
- Workflows for `tesla-inference-flake` could:
  - `nix flake check`
  - `nix build .#packages.x86_64-linux.{default,ollama-official-binaries}`
  - Use Attic post-build hooks or explicit `attic push`.

This gives green checks on PRs without depending on nix-ci’s upload behavior.

### 3.2 Scheduled homelab builder

- NixOS service + timer on a builder host (e.g. `attic-cache` or `homeserver`).
- On a schedule or webhook:
  - `git pull` the repo
  - run `nix flake check` and key builds
  - push artifacts to Attic

You can surface status via Attic observatory or simple logs.

### 3.3 Developer-side pre-push checks

For critical repos you can also:

- Add a `pre-push` hook running `nix flake check` and selected `nix build` invocations.
- Let the homelab builder/Actions runner be the source of truth for heavier jobs (CUDA builds, Ollama binaries).

## 4. Recommended split of responsibilities

- **nix-ci.com**
  - Keep enabled as a *read cache* and lightweight CI signal.
  - Accept that very large artifacts (e.g. 1.9 GiB Ollama NARs) may occasionally fail to upload.

- **Attic + homelab CI**
  - Treat this as the **authoritative** CI and cache for heavyweight builds.
  - You fully control size limits, retention, and upload policies.

This combination gives you fast remote cache hits (nix-ci + Attic) while ensuring large CUDA/Ollama builds succeed and are cached under your control.