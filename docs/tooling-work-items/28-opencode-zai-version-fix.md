# 28 OpenCode-Zai Version Fix

Status: `done`

Branch: `design/router-dhcp-provider-observability-v2`

## Problem

`opencode` (aliased to `opencode-zai` when fnox is enabled) was running the
fnox-flake's own bundled opencode binary (`1.1.14`) instead of the version
provided by the `llm-agents.nix` overlay (`1.3.2`).

Root cause: `fnox-flake` packages `opencode-zai` with its own nixpkgs-pinned
opencode dependency. The `defaultWrappedCommandSpecs` in fnox-flake generates
`opencode-zai` at build time from that internal pin, ignoring the repo's
`pkgs.llm-agents.opencode` overlay.

`opencode-raw` (the unwrapped binary) correctly used `1.3.2` because it came
from `pkgs.llm-agents` directly. But the default `opencode` alias pointed at
the fnox-flake wrapper, which dragged in the older version.

## Fix

Same pattern as `gh-fnox`, `bw-fnox`, etc.:

1. Added `pkgs/opencode-zai.nix` — a local `writeShellApplication` wrapper
   that injects `Z_AI_API_KEY` via fnox and `exec opencode "$@"`, where
   `opencode` resolves to `pkgs.llm-agents.opencode`.
2. Exposed it via `overlays/packages.nix` with
   `opencode = final.llm-agents.opencode` as the explicit dependency.
3. Added `"opencode-zai"` to the `lib.removeAttrs` exclusion list in
   `modules/home-manager/common/fnox.nix` so the fnox-flake's version is
   dropped in favour of the local one.

## Validation

- `opencode --version` now reports the same version as `opencode-raw`
- `Z_AI_API_KEY` injection still works via fnox (same as before)
- `nix-instantiate --parse pkgs/opencode-zai.nix` passes
