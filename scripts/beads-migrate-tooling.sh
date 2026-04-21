#!/usr/bin/env bash
set -euo pipefail

# Populate the beads_rust store from the current tooling markdown queue.
#
# Preconditions:
# - Run from anywhere inside this git repo.
# - `beads-rust` must be installed and on PATH.
# - `.beads/` has been initialised via `beads-rust init`.
#
# This script only ingests tooling work items that are still `ready` or
# `in-progress`. Already-`done` items remain in markdown-only history.

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

beads_cmd="${BEADS_RUST_CMD:-beads-rust}"

if ! command -v "${beads_cmd}" >/dev/null 2>&1; then
  echo "error: ${beads_cmd} not found on PATH." >&2
  echo "hint: this repo uses the repo-managed \`beads-rust\` wrapper to avoid colliding with the Homebrew viewer \`br\` command." >&2
  echo "hint: if you intentionally installed the upstream CLI as raw \`br\`, rerun with BEADS_RUST_CMD=br." >&2
  exit 1
fi

queue_readme="docs/tooling-work-items/README.md"
if [[ ! -f "${queue_readme}" ]]; then
  echo "error: ${queue_readme} not found; run from the unified-nix-configuration repo" >&2
  exit 1
fi

# Extract the ordered list of work-item files from the Current Ranked Queue
mapfile -t items < <(awk '/^## Current Ranked Queue/{flag=1; next} /^## /{flag=0} flag' "${queue_readme}" \
  | sed -nE 's|.*\(\./([^)]*\.md)\).*|\1|p')

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

  # Pull a simple description and validation slice, if present.
  desc=$(sed -n '/^## Goal/,/^## /p' "${file}" | sed '1d;$d') || true
  if [[ -z "${desc}" ]]; then
    desc="See ${file} for full context."
  fi

  criteria=$(sed -n '/^## Validation/,/^## /p' "${file}" | sed '1d;$d') || true
  if [[ -n "${criteria}" ]]; then
    desc="${desc}

Validation:
${criteria}"
  fi

  br_status="open"
  if [[ "${status}" == "in-progress" ]]; then
    br_status="in_progress"
  fi

  echo "[${beads_cmd}] creating bead for: ${title} (status=${status}, priority=${priority})" >&2

  "${beads_cmd}" create "${title}" \
    --type Task \
    --priority "${priority}" \
    --labels tooling \
    --description "${desc}" \
    --status "${br_status}" \
    --external-ref "${file}" || {
      echo "error: ${beads_cmd} create failed for ${file}" >&2
      exit 1
    }

  priority=$((priority + 1))
done

# Export the current SQLite state back to JSONL so it can be committed.
if "${beads_cmd}" sync --flush-only >/dev/null 2>&1; then
  echo "${beads_cmd} sync --flush-only completed; .beads/issues.jsonl updated" >&2
else
  echo "warning: ${beads_cmd} sync --flush-only failed; check the beads_rust CLI version" >&2
fi

echo "tooling queue migration to beads_rust completed (subject to any warnings above)." >&2
