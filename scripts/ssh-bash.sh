#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ssh-bash [ssh options...] host
  ssh-bash [ssh options...] host -- command ...
  local-command | ssh-bash [ssh options...] host

Purpose:
  Open a remote Bash shell or run a command through Bash even when the remote
  account's default shell is fish or another non-POSIX shell.

Examples:
  ssh-bash router
  ssh-bash -o BatchMode=yes -o ConnectTimeout=5 router -- systemctl status kea-dhcp4-server
  ssh-bash router -- "journalctl -u kea-dhcp-ddns-server --since '10 min ago' | tail -n 40"
  cat ./script.sh | ssh-bash router

Notes:
  - With no command and an interactive stdin, ssh-bash starts a remote login
    Bash shell.
  - With no command and piped stdin, ssh-bash runs the incoming script via
    remote Bash stdin mode.
  - When passing a shell pipeline or redirection, provide it as a single
    argument after `--`.
EOF
}

quote_single() {
  local value=${1//\'/\'\"\'\"\'}
  printf "'%s'" "$value"
}

join_command_words() {
  local word
  local joined=""

  for word in "$@"; do
    if [[ -n "$joined" ]]; then
      joined+=" "
    fi
    joined+="$(quote_single "$word")"
  done

  printf '%s' "$joined"
}

require_option_value() {
  local option="$1"
  local value="${2-}"
  if [[ -z "$value" ]]; then
    echo "ssh-bash: missing value for ssh option $option" >&2
    exit 2
  fi
}

ssh_bin="${SSH_BASH_SSH:-ssh}"
declare -a ssh_args=()
host=""
tty_option_seen=0

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -t|-tt|-T)
      ssh_args+=("$1")
      tty_option_seen=1
      shift
      ;;
    -4|-6|-A|-a|-C|-f|-G|-g|-K|-k|-M|-N|-n|-q|-s|-V|-v|-X|-x|-Y|-y)
      ssh_args+=("$1")
      shift
      ;;
    -b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|-Q|-R|-S|-W|-w)
      require_option_value "$1" "${2-}"
      ssh_args+=("$1" "$2")
      shift 2
      ;;
    -*)
      echo "ssh-bash: unsupported ssh option $1" >&2
      exit 2
      ;;
    *)
      host="$1"
      shift
      break
      ;;
  esac
done

if [[ -z "$host" ]]; then
  usage >&2
  exit 2
fi

declare -a command_args=("$@")

if ((${#command_args[@]} > 0)) && [[ ${command_args[0]} == "--" ]]; then
  command_args=("${command_args[@]:1}")
fi

remote_bootstrap=$'if [ -x /run/current-system/sw/bin/bash ]; then\n  exec /run/current-system/sw/bin/bash "$@"\nelif [ -x /bin/bash ]; then\n  exec /bin/bash "$@"\nelif command -v bash >/dev/null 2>&1; then\n  exec "$(command -v bash)" "$@"\nelse\n  echo "ssh-bash: remote bash not found" >&2\n  exit 127\nfi'
quoted_bootstrap="$(quote_single "$remote_bootstrap")"

if ((${#command_args[@]} > 0)); then
  if ((${#command_args[@]} == 1)); then
    remote_payload="${command_args[0]}"
  else
    remote_payload="$(join_command_words "${command_args[@]}")"
  fi

  remote_command="exec /bin/sh -lc ${quoted_bootstrap} sh -lc $(quote_single "$remote_payload")"
  exec "$ssh_bin" "${ssh_args[@]}" "$host" "$remote_command"
fi

if [[ -t 0 ]]; then
  if ((tty_option_seen == 0)); then
    ssh_args+=("-tt")
  fi

  remote_command="exec /bin/sh -lc ${quoted_bootstrap} sh -l"
  exec "$ssh_bin" "${ssh_args[@]}" "$host" "$remote_command"
fi

remote_command="exec /bin/sh -lc ${quoted_bootstrap} sh -s"
exec "$ssh_bin" "${ssh_args[@]}" "$host" "$remote_command"
