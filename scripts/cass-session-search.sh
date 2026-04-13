#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cass-session-search [--roots] [RG_ARGS...] PATTERN

Search prior coding-agent sessions (Claude, Copilot, Gemini) for PATTERN.

Examples:
  cass-session-search router dashboard
  cass-session-search --fixed-strings 'agent-guards.nix'
  cass-session-search --roots

Options:
  --roots   Print the session roots that will be searched and exit.

All additional arguments are passed through to ripgrep. The default
session roots are:
  - $HOME/.copilot/session-state
  - $HOME/.claude/sessions
  - $HOME/.gemini/history

You can override the search roots by setting CASS_SESSION_ROOTS to a
colon-separated list of directories.
EOF
}

if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  usage
  exit 0
fi

# Build list of session roots
roots=()

if [[ -n "${CASS_SESSION_ROOTS-}" ]]; then
  IFS=':' read -r -a roots <<<"$CASS_SESSION_ROOTS"
else
  default_roots=(
    "$HOME/.copilot/session-state"
    "$HOME/.claude/sessions"
    "$HOME/.gemini/history"
  )
  for path in "${default_roots[@]}"; do
    if [[ -d "$path" ]]; then
      roots+=("$path")
    fi
  done
fi

if [[ "${1-}" == "--roots" ]]; then
  if ((${#roots[@]} == 0)); then
    echo "cass-session-search: no session roots found" >&2
    exit 1
  fi
  printf '%s
' "${roots[@]}"
  exit 0
fi

if ((${#roots[@]} == 0)); then
  echo "cass-session-search: no session roots found" >&2
  echo "Set CASS_SESSION_ROOTS or ensure local agent session directories exist." >&2
  exit 1
fi

if ((${#} == 0)); then
  usage >&2
  exit 1
fi

# Delegate to ripgrep; runtimeInputs ensure rg is on PATH.
exec rg --no-messages --hidden "$@" "${roots[@]}"