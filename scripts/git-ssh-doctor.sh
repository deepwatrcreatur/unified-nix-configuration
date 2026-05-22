#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: git-ssh-doctor [--no-github-probe] [--no-git-log]

Read-only diagnostics for Git SSH signing and GitHub SSH transport.

Checks:
  - Git SSH signing configuration
  - allowed_signers presence
  - SSH_AUTH_SOCK presence and socket state
  - loaded SSH identities via ssh-add -l
  - effective SSH config for github.com
  - optional GitHub SSH transport probe
  - optional latest-commit signature inspection

Options:
  --no-github-probe  Skip the live GitHub SSH transport probe.
  --no-git-log       Skip `git log --show-signature` inspection.
  -h, --help         Show this help.
EOF
}

github_probe=1
git_log_probe=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-github-probe)
      github_probe=0
      shift
      ;;
    --no-git-log)
      git_log_probe=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "git-ssh-doctor: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

status_line() {
  local level="$1"
  local label="$2"
  local detail="$3"
  printf '%-4s %-22s %s\n' "$level" "$label" "$detail"
}

value_or_unset() {
  local key="$1"
  local value

  if value="$(git config --get "$key" 2>/dev/null)" && [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  else
    printf '<unset>\n'
  fi
}

print_header() {
  printf '\n[%s]\n' "$1"
}

for cmd in git ssh ssh-add; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    status_line FAIL prerequisites "missing required command: $cmd"
    exit 1
  fi
done

print_header "git-config"
gpg_format="$(value_or_unset gpg.format)"
commit_gpgsign="$(value_or_unset commit.gpgsign)"
tag_gpgsign="$(value_or_unset tag.gpgsign)"
signing_key="$(value_or_unset user.signingkey)"
allowed_signers="$(git config --path --get gpg.ssh.allowedSignersFile 2>/dev/null || true)"

status_line INFO gpg.format "$gpg_format"
status_line INFO commit.gpgsign "$commit_gpgsign"
status_line INFO tag.gpgsign "$tag_gpgsign"
status_line INFO user.signingkey "$signing_key"

if [[ "$gpg_format" == "ssh" ]]; then
  status_line PASS signing-config "Git is configured for SSH signing"
else
  status_line FAIL signing-config "expected gpg.format=ssh"
fi

print_header "allowed-signers"
if [[ -n "$allowed_signers" ]]; then
  status_line INFO allowedSignersFile "$allowed_signers"
  if [[ -f "$allowed_signers" ]]; then
    status_line PASS allowed-signers "file exists"
  else
    status_line FAIL allowed-signers "configured file is missing"
  fi
else
  status_line FAIL allowed-signers "gpg.ssh.allowedSignersFile is unset"
fi

print_header "ssh-agent"
if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
  status_line INFO SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
  if [[ -S "${SSH_AUTH_SOCK}" ]]; then
    status_line PASS auth-sock "socket exists"
  else
    status_line FAIL auth-sock "path is set but socket is missing"
  fi
else
  status_line FAIL auth-sock "SSH_AUTH_SOCK is unset"
fi

ssh_add_output=""
ssh_add_status=0
if ssh_add_output="$(ssh-add -l 2>&1)"; then
  first_identity="$(printf '%s\n' "$ssh_add_output" | head -n 1)"
  status_line PASS ssh-add "$first_identity"
else
  ssh_add_status=$?
  case "$ssh_add_status" in
    1)
      status_line WARN ssh-add "agent reachable but no identities loaded"
      ;;
    2)
      if printf '%s' "$ssh_add_output" | grep -qi 'Operation not permitted'; then
        status_line WARN ssh-add "agent socket exists but runtime access is not permitted"
      else
        status_line FAIL ssh-add "could not contact SSH agent"
      fi
      ;;
    *)
      first_line="$(printf '%s\n' "$ssh_add_output" | head -n 1)"
      status_line FAIL ssh-add "${first_line:-unknown ssh-add failure}"
      ;;
  esac
fi

print_header "ssh-config github.com"
ssh_config_path="$HOME/.ssh/config"
ssh_config_args=()
if [[ -r "$ssh_config_path" ]]; then
  ssh_config_args=(-F "$ssh_config_path")
fi

ssh_g_output=""
if ssh_g_output="$(ssh "${ssh_config_args[@]}" -G github.com 2>&1)"; then
  while IFS= read -r line; do
    case "$line" in
      identityfile\ *|identitiesonly\ *|addkeystoagent\ *|identityagent\ *)
        status_line INFO github.com "$line"
        ;;
      esac
  done <<<"$ssh_g_output"
else
  first_line="$(printf '%s\n' "$ssh_g_output" | head -n 1)"
  if printf '%s' "$ssh_g_output" | grep -qiE 'Bad owner or permissions|Can.t open user config file|Permission denied'; then
    status_line WARN ssh-config "${first_line:-ssh -G failed}"
  else
    status_line FAIL ssh-config "${first_line:-ssh -G failed}"
  fi
fi

print_header "github-transport"
if [[ "$github_probe" -eq 0 ]]; then
  status_line SKIP github-probe "disabled by flag"
else
  github_output=""
  github_status=0
  if github_output="$(ssh "${ssh_config_args[@]}" -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1)"; then
    status_line PASS github-probe "GitHub SSH transport succeeded"
  else
    github_status=$?
    if printf '%s' "$github_output" | grep -qi 'successfully authenticated'; then
      status_line PASS github-probe "GitHub accepted SSH auth (exit $github_status)"
    else
      first_line="$(printf '%s\n' "$github_output" | head -n 1)"
      status_line FAIL github-probe "${first_line:-GitHub SSH probe failed} (exit $github_status)"
    fi
  fi
fi

print_header "git-log"
if [[ "$git_log_probe" -eq 0 ]]; then
  status_line SKIP git-log "disabled by flag"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_log_output=""
  git_log_status=0
  if git_log_output="$(git log -1 --show-signature --no-patch 2>&1)"; then
    first_sig_line="$(printf '%s\n' "$git_log_output" | rg -m 1 'Good .*signature|No signature|gpg:' || true)"
    status_line PASS git-log "${first_sig_line:-latest commit inspected}"
  else
    git_log_status=$?
    first_line="$(printf '%s\n' "$git_log_output" | head -n 1)"
    status_line FAIL git-log "${first_line:-git log probe failed} (exit $git_log_status)"
  fi
else
  status_line SKIP git-log "not running inside a git work tree"
fi

print_header "how-to-read"
status_line INFO meaning "FAIL signing-config => Git SSH signing is not configured"
status_line INFO meaning "WARN ssh-add with PASS github-probe => transport works but agent is empty"
status_line INFO meaning "FAIL github-probe with PASS signing-config => signing config exists but GitHub SSH auth is failing"
