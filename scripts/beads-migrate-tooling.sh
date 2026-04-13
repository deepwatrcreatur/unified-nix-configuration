#!/usr/bin/env bash
set -euo pipefail

# Populate the beads_rust store from the current tooling markdown queue.
#
# Preconditions:
# - Run from anywhere inside this git repo.
# - `br` (beads_rust) must be installed and on PATH.
# - `.beads/` has been initialised via `br init`.
#
# This script only ingests tooling work items that are still `ready` or
# `in-progress`. Already-`done` items remain in markdown-only history.

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

if ! command -v br >/dev/null 2>&1; then
  echo "error: br (beads_rust) not found on PATH; install it first" >&2
  exit 1
fi

queue_readme="docs/tooling-work-items/README.md"
if [[ ! -f "${queue_readme}" ]]; then
  echo "error: ${queue_readme} not found; run from the unified-nix-configuration repo" >&2
  exit 1
fi

# Extract the ordered list of work-item files from the Current Ranked Queue
mapfile -t items < <(sed -n '/^## Current Ranked Queue/,/^$/p' "${queue_readme}" \
  | grep ' - `' \
  | sed 's/.*(\.\/(.*\.md)).*/\1/')

if [[ ${#items[@]} -eq 0 ]]; then
  echo "no tooling work items found in README; nothing to migrate" >&2
  exit 0
fi

priority=1
for rel in "${items[@]}"; do
  file="docs/tooling-work-items/${rel}"
  if [[ ! -f "${file}" ]]; then
    echo "warning: listed work-item ${file} is missing; skipping" >&2
    continue
  fi

  status=$(sed -n 's/^Status: `\(.*\)`/\1/p' "${file}")
  case "${status}" in
    ready|in-progress) ;;
    *)
      # Skip blocked/done/other states
      continue
      ;;
  esac

  title=$(sed -n '1s/^# //p' "${file}")
  if [[ -z "${title}" ]]; then
    echo "warning: could not parse title from ${file}; skipping" >&2
    continue
  fi

  # Pull a simple description and acceptance-criteria slice, if present.
  desc=$(sed -n '/^## Goal/,/^## /p' "${file}" | sed '1d;$d') || true
  if [[ -z "${desc}" ]]; then
    desc="See ${file} for full context."
  fi

  criteria=$(sed -n '/^## Validation/,/^## /p' "${file}" | sed '1d;$d') || true
  if [[ -z "${criteria}" ]]; then
    criteria="See ${file} for validation details."
  fi

  echo "[br] creating bead for: ${title} (status=${status}, priority=${priority})" >&2

  br create "${title}" \
    --type Task \
    --priority "${priority}" \
    --labels tooling \
    --description "${desc}" \
    --acceptance-criteria "${criteria}" || {
      echo "error: br create failed for ${file}" >&2
      exit 1
    }

  priority=$((priority + 1))
done

# Export the current SQLite state back to JSONL so it can be committed.
if br sync --flush-only >/dev/null 2>&1; then
  echo "br sync --flush-only completed; .beads/issues.jsonl updated" >&2
else
  echo "warning: br sync --flush-only failed; check beads_rust version" >&2
fi

echo "tooling queue migration to beads_rust completed (subject to any warnings above)." >&2
