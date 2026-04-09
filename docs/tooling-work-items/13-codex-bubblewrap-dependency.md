# 13 Codex Bubblewrap Dependency

Status: `done`

Suggested branch: `fix/tooling-codex-bubblewrap`

## Goal

Ensure Codex uses a valid system `bubblewrap` path on NixOS instead of probing
the FHS-specific `/usr/bin/bwrap`.

## Why

Codex reported the following error:
`Codex could not find system bubblewrap at /usr/bin/bwrap. Please install bubblewrap with your package manager. Codex will use the vendored bubblewrap in the meantime.`

On NixOS, `/usr/bin/bwrap` is the wrong integration point. The real fix is to
patch the packaged Codex binary so its Linux sandbox code prefers the Nix store
path for `bubblewrap`.

## Scope

- Identify where Codex is installed or configured in this repo (likely in Home Manager or a coding-agent layer).
- Patch the packaged Codex derivation so its Linux sandbox code uses the Nix
  store path for `bubblewrap`.
- Verify if this affects all hosts or just specific ones (e.g., those using coding-agent modules).

## Non-Goals

- Replacing the vendored bubblewrap in Codex's own build process if it's external to this repo.
- Broad changes to sandboxing policy beyond fixing the Codex warning/error.

## Implementation Notes

`pkgs.llm-agents.codex` is overridden in [`overlays/flake-inputs.nix`](../../overlays/flake-inputs.nix)
to rewrite Codex's hardcoded Linux `bubblewrap` path from `/usr/bin/bwrap` to the
Nix store path `${pkgs.bubblewrap}/bin/bwrap` at build time.

This removes the NixOS-specific startup warning without needing to mutate `/usr`
or rely on the vendored fallback.

## Validation

- `strings $(command -v codex) | rg '/nix/store/.*/bin/bwrap'` should show the
  patched system `bubblewrap` path.
- Starting Codex on NixOS should no longer emit the `/usr/bin/bwrap` warning.
