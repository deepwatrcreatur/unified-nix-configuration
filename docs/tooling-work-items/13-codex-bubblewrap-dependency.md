# 13 Codex Bubblewrap Dependency

Status: `in-progress`

Suggested branch: `fix/tooling-codex-bubblewrap`

## Goal

Ensure `bubblewrap` (bwrap) is correctly available for Codex so it doesn't fall back to its vendored version or fail to find the system binary at `/usr/bin/bwrap`.

## Why

Codex reported the following error:
`Codex could not find system bubblewrap at /usr/bin/bwrap. Please install bubblewrap with your package manager. Codex will use the vendored bubblewrap in the meantime.`

In a Nix-managed system, we should either provide `bubblewrap` in the PATH or ensure it's available in the expected location if Codex is hardcoded to look for it at `/usr/bin/bwrap`.

## Scope

- Identify where Codex is installed or configured in this repo (likely in Home Manager or a coding-agent layer).
- Add `bubblewrap` to the environment's `home.packages` or `environment.systemPackages`.
- If Codex specifically requires `/usr/bin/bwrap`, ensure `programs.bubblewrap.enable = true;` is set on NixOS hosts or provide a suitable workaround.
- Verify if this affects all hosts or just specific ones (e.g., those using coding-agent modules).

## Non-Goals

- Replacing the vendored bubblewrap in Codex's own build process if it's external to this repo.
- Broad changes to sandboxing policy beyond fixing the Codex warning/error.

## Implementation Notes

`pkgs.bubblewrap` added to `home.packages` in `modules/home-manager/common/coding-agents.nix`
guarded by `pkgs.stdenv.hostPlatform.isLinux` (bubblewrap is not available on Darwin).

On NixOS, `/usr/bin/bwrap` cannot be provided — NixOS only manages `/usr/bin/env` and `/usr`
is read-only from the Nix store. Codex's check for `/usr/bin/bwrap` will still fail on NixOS
hosts, but the vendored fallback is functional and `bwrap` is available in PATH for any
subsequent PATH-based lookups. Modern NixOS enables unprivileged user namespaces so the
in-PATH bwrap works without setuid.

## Validation

- `command -v bwrap` should return a valid path in the agent's shell after rebuild.
- The Codex `/usr/bin/bwrap` warning is a NixOS limitation (read-only `/usr`) and cannot
  be fully eliminated without patching Codex itself.
