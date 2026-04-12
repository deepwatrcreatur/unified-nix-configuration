#!/usr/bin/env bash
set -euo pipefail

json_mode=0
if [[ "${1:-}" == "--json" ]]; then
  json_mode=1
  shift
fi

emit_allow() {
  if [[ "$json_mode" -eq 1 ]]; then
    printf '{}\n'
  fi
}

emit_block() {
  local message="$1"
  printf 'BLOCK: %s\n' "$message" >&2
  if [[ "$json_mode" -eq 1 ]]; then
    jq -Rn --arg message "[repo-guard] $message" '{ permissionDecision: "ask", message: $message }'
  fi
  exit 1
}

if [[ "${AGENT_GUARD_SKIP:-0}" == "1" || "${RTK_BYPASS:-0}" == "1" ]]; then
  emit_allow
  exit 0
fi

payload=""
cmd=""

if [[ "$#" -gt 0 ]]; then
  cmd="$*"
elif [[ ! -t 0 ]]; then
  payload="$(cat)"
  if [[ -n "$payload" ]]; then
    if cmd="$(printf '%s' "$payload" | jq -r '
      .tool_input.command // .tool_input.cmd // .command // .cmd // empty
    ' 2>/dev/null)"; then
      :
    else
      cmd="$payload"
    fi
  fi
fi

if [[ -z "$cmd" ]]; then
  emit_allow
  exit 0
fi

cmd_lower="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

is_safe_rm_target() {
  case "$1" in
    node_modules|*/node_modules|.next|*/.next|dist|*/dist|build|*/build|coverage|*/coverage|__pycache__|*/__pycache__|.cache|*/.cache|.direnv|*/.direnv|.turbo|*/.turbo|result|*/result)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])rm([[:space:]]|$).*([[:space:]]-[[:alnum:]]*r[[:alnum:]]*|[[:space:]]--recursive)([[:space:]]|$)'; then
  rm_targets="$(printf '%s' "$cmd" | sed -E 's/^.*(^|[[:space:]])rm([[:space:]]+(-[[:alnum:]]+|--[[:alnum:]-]+))*[[:space:]]+//')"
  safe_only=1
  for target in $rm_targets; do
    if [[ "$target" == -* ]]; then
      continue
    fi
    if ! is_safe_rm_target "$target"; then
      safe_only=0
      break
    fi
  done
  if [[ "$safe_only" -eq 0 ]]; then
    emit_block "Destructive command detected: recursive delete."
  fi
fi

if printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force-with-lease|--force|-f)([[:space:]]|$)'; then
  emit_block "Destructive command detected: git force-push rewrites remote history."
fi

if printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'; then
  emit_block "Destructive command detected: git reset --hard discards local changes."
fi

if printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+clean[[:space:]].*(-f.*-d|-d.*-f)([[:space:]]|$)'; then
  emit_block "Destructive command detected: git clean removes untracked files."
fi

if printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-d[[:space:]]'; then
  if printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-d[[:space:]]+-'; then
    :
  elif printf '%s' "$cmd_lower" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-d[[:space:]]'; then
    emit_block "Destructive command detected: git branch -D force-deletes a branch."
  fi
fi

if printf '%s' "$cmd_lower" | grep -Eq 'drop[[:space:]]+(table|database)\b'; then
  emit_block "Destructive command detected: SQL DROP removes database objects."
fi

if printf '%s' "$cmd_lower" | grep -Eq '\btruncate\b'; then
  emit_block "Destructive command detected: SQL TRUNCATE removes all rows."
fi

if printf '%s' "$cmd_lower" | grep -Eq 'delete[[:space:]]+from\b' && ! printf '%s' "$cmd_lower" | grep -Eq '\bwhere\b'; then
  emit_block "Destructive command detected: SQL DELETE without WHERE."
fi

emit_allow
