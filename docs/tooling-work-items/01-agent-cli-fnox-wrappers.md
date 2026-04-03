# 01 Agent CLI Fnox Wrappers

Status: `ready`

Suggested branch: `feat/tooling-agent-cli-fnox-wrappers`

## Goal

Wrap the agent CLIs that regularly need API-key injection from `fnox` while
keeping the current repo conventions around canonical names and fallbacks.

## Scope

- audit existing `fnox` wrapped commands and agent packages
- identify which of `opencode`, `claude-code`, `gemini-cli`, and `droid`
  already have wrapped command specs available
- wire the high-value ones into the repo’s alias/package path using the same
  fallback style already used for `gh` and `bw`
- keep raw commands available if the wrapper is a convenience layer rather than
  a true replacement

## Non-Goals

- wrapping generic build tools like `nixos-rebuild`, `nh`, or `just`
- broad shell refactors unrelated to `fnox`

## Validation

- affected Home Manager modules evaluate cleanly
- wrapped command aliases or package selections resolve correctly when
  `<tool>-fnox` exists and fall back cleanly when it does not
- docs/comments make the policy obvious to future maintainers
