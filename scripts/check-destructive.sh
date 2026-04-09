#!/usr/bin/env bash
# scripts/check-destructive.sh — Repo-wide destructive command guard
# Can take command as argument: ./check-destructive.sh "rm -rf /"
# Or from JSON stdin (for rtk/gemini/claude hooks): echo '{"command":"..."}' | ./check-destructive.sh
set -euo pipefail

# Allow intentional bypass via environment variable
if [[ "${AGENT_GUARD_SKIP:-0}" == "1" ]]; then
  exit 0
fi

CMD=""
INPUT=""

if [ "$#" -gt 0 ]; then
  CMD="$*"
else
  # Read stdin (JSON or raw string)
  if [ ! -t 0 ]; then
    INPUT=$(cat)
    if [[ "$INPUT" =~ ^\{ ]]; then
      # Try to extract "command" or "tool_input.command"
      CMD=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
      if [ -z "$CMD" ]; then
         # Try tool_input nested
         CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json; data=json.loads(sys.stdin.read()); print(data.get("tool_input",{}).get("command", data.get("command","")))' 2>/dev/null || true)
      fi
    else
      CMD="$INPUT"
    fi
  fi
fi

if [ -z "$CMD" ]; then
  # No command found, allow
  exit 0
fi

# Normalize: lowercase for case-insensitive SQL matching
CMD_LOWER=$(printf '%s' "$CMD" | tr '[:upper:]' '[:lower:]')

# --- Check for safe exceptions ---
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+)' 2>/dev/null; then
  SAFE_ONLY=true
  # Strip everything up to the first non-flag argument after rm
  RM_ARGS=$(printf '%s' "$CMD" | sed -E 's/.*rm\s+(-[a-zA-Z]+\s+|--[a-z-]+\s+)*//')
  for target in $RM_ARGS; do
    case "$target" in
      */node_modules|node_modules|*/\.next|\.next|*/dist|dist|*/__pycache__|__pycache__|*/\.cache|\.cache|*/build|build|*/\.turbo|\.turbo|*/coverage|coverage|*/\.direnv|\.direnv|*/result|result)
        ;; # safe target
      -*)
        ;; # flag, skip
      *)
        SAFE_ONLY=false
        break
        ;;
    esac
  done
  if [ "$SAFE_ONLY" = true ]; then
    exit 0
  fi
fi

# --- Destructive pattern checks ---
WARN=""

# rm -rf / rm -r / rm --recursive
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r|--recursive)' 2>/dev/null; then
  WARN="Destructive: recursive delete (rm -r). This permanently removes files."
fi

# DROP TABLE / DROP DATABASE / DELETE FROM (without WHERE)
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE 'drop\s+(table|database)' 2>/dev/null; then
  WARN="Destructive: SQL DROP detected. This permanently deletes database objects."
fi

if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -q 'delete from' 2>/dev/null && ! printf '%s' "$CMD_LOWER" | grep -q 'where'; then
  WARN="Destructive: SQL DELETE without WHERE clause detected. This deletes all rows in the table."
fi

# TRUNCATE
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE '\btruncate\b' 2>/dev/null; then
  WARN="Destructive: SQL TRUNCATE detected. This deletes all rows from a table."
fi

# git push --force / git push -f
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+push\s+.*(-f\b|--force)' 2>/dev/null; then
  WARN="Destructive: git force-push rewrites remote history. Other contributors may lose work."
fi

# git reset --hard
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+reset\s+--hard' 2>/dev/null; then
  WARN="Destructive: git reset --hard discards all uncommitted changes."
fi

# git branch -D (force delete)
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+branch\s+-D' 2>/dev/null; then
  WARN="Destructive: git branch -D force-deletes a branch even if not merged."
fi

# kubectl delete
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'kubectl\s+delete' 2>/dev/null; then
  WARN="Destructive: kubectl delete removes Kubernetes resources. May impact production."
fi

# docker rm -f / docker system prune
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'docker\s+(rm\s+-f|system\s+prune)' 2>/dev/null; then
  WARN="Destructive: Docker force-remove or prune. May delete running containers or cached images."
fi

# --- Output ---
if [ -n "$WARN" ]; then
  echo "BLOCK: $WARN" >&2
  # For Claude/Gemini hooks, we might want to output JSON
  if [[ "${1:-}" == "--json" || ( -n "$INPUT" && "$INPUT" =~ ^\{ ) ]]; then
    printf '{"permissionDecision":"ask","message":"[repo-guard] %s"}\n' "$WARN"
  fi
  exit 1
else
  if [[ "${1:-}" == "--json" || ( -n "$INPUT" && "$INPUT" =~ ^\{ ) ]]; then
    echo '{}'
  fi
  exit 0
fi
