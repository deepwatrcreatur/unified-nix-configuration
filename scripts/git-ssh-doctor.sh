#!/usr/bin/env bash
set -u

git_cmd="${GIT:-git}"
ssh_cmd="${SSH:-ssh}"
ssh_add_cmd="${SSH_ADD:-ssh-add}"
signature_rev="${1:-HEAD}"

status_ok=0
status_warn=0
status_fail=0

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

print_section() {
  printf '\n== %s ==\n' "$1"
}

record_status() {
  case "$1" in
    ok) status_ok=$((status_ok + 1)) ;;
    warn) status_warn=$((status_warn + 1)) ;;
    fail) status_fail=$((status_fail + 1)) ;;
  esac
}

print_status() {
  level="$1"
  shift
  record_status "$level"
  printf '[%s] %s\n' "$level" "$*"
}

print_kv() {
  key="$1"
  value="$2"
  printf '  %-28s %s\n' "$key" "$value"
}

git_config_value() {
  key="$1"
  "$git_cmd" config --get "$key" 2>/dev/null || true
}

git_config_origin_value() {
  key="$1"
  "$git_cmd" config --show-origin --get "$key" 2>/dev/null || true
}

trim_newline() {
  printf '%s' "$1" | tr '\n' ' '
}

resolve_path() {
  path="$1"
  if [ "$path" = "~" ]; then
    printf '%s' "$HOME"
  elif [ "$(printf '%.2s' "$path")" = "~/" ]; then
    printf '%s/%s' "$HOME" "${path#??}"
  else
    printf '%s' "$path"
  fi
}

agent_probe() {
  if ! has_cmd "$ssh_add_cmd"; then
    print_status warn "ssh-add not available; cannot inspect loaded identities"
    return
  fi

  output="$("$ssh_add_cmd" -l 2>&1)"
  code=$?

  case $code in
    0)
      print_status ok "ssh-agent has loaded identities"
      printf '%s\n' "$output" | sed 's/^/    /'
      ;;
    1)
      print_status warn "ssh-agent socket is reachable but no identities are loaded"
      printf '%s\n' "$output" | sed 's/^/    /'
      ;;
    *)
      if printf '%s' "$output" | grep -qi "operation not permitted"; then
        print_status warn "ssh-add probe was blocked by the current execution environment"
      else
        print_status fail "ssh-add could not inspect the agent"
      fi
      printf '%s\n' "$output" | sed 's/^/    /'
      ;;
  esac
}

transport_probe() {
  if ! has_cmd "$ssh_cmd"; then
    print_status warn "ssh not available; cannot probe GitHub transport"
    return
  fi

  output="$("$ssh_cmd" -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ControlMaster=no -o ControlPath=none git@github.com 2>&1)"
  code=$?

  case $code in
    1)
      if printf '%s' "$output" | grep -qi "successfully authenticated"; then
        print_status ok "GitHub SSH transport/auth is working"
      else
        print_status warn "GitHub SSH returned exit 1 without the expected authentication message"
      fi
      ;;
    0)
      print_status ok "GitHub SSH transport/auth is working"
      ;;
    *)
      if printf '%s' "$output" | grep -Eqi "temporary failure in name resolution|name or service not known|operation not permitted"; then
        print_status warn "GitHub SSH probe was blocked by the current execution environment"
      else
        print_status fail "GitHub SSH transport/auth probe failed"
      fi
      ;;
  esac

  printf '%s\n' "$output" | sed 's/^/    /'
}

signature_probe() {
  if ! has_cmd "$git_cmd"; then
    print_status warn "git not available; cannot inspect recent signatures"
    return
  fi

  if ! "$git_cmd" rev-parse --verify "$signature_rev" >/dev/null 2>&1; then
    print_status warn "requested revision cannot be resolved for signature inspection: $signature_rev"
    return
  fi

  output="$("$git_cmd" log --show-signature -n 1 "$signature_rev" 2>&1)"
  code=$?

  if [ $code -ne 0 ]; then
    print_status fail "git log --show-signature failed for $signature_rev"
    printf '%s\n' "$output" | sed 's/^/    /'
    return
  fi

  if printf '%s' "$output" | grep -q "No signature"; then
    print_status warn "$signature_rev is unsigned; signing verification probe is inconclusive"
  elif printf '%s' "$output" | grep -Eq "Good .*signature|Good \"git\" signature"; then
    print_status ok "signature verifies successfully for $signature_rev"
  elif printf '%s' "$output" | grep -q "Can't check signature: No public key"; then
    print_status warn "$signature_rev is signed, but the verification key is unavailable locally"
  else
    print_status warn "signature status needs manual review for $signature_rev"
  fi

  printf '%s\n' "$output" | sed 's/^/    /'
}

print_section "Git SSH / Signing Doctor"
print_kv "host" "$(hostname 2>/dev/null || echo unknown)"
print_kv "repo" "$(pwd)"

print_section "Git Signing Config"
email="$(git_config_value user.email)"
signing_key="$(git_config_value user.signingkey)"
gpg_format="$(git_config_value gpg.format)"
commit_sign="$(git_config_value commit.gpgsign)"
tag_sign="$(git_config_value tag.gpgsign)"
allowed_signers_cfg="$(git_config_value gpg.ssh.allowedSignersFile)"

print_kv "user.email" "${email:-<unset>}"
print_kv "user.signingkey" "${signing_key:-<unset>}"
print_kv "gpg.format" "${gpg_format:-<unset>}"
print_kv "commit.gpgsign" "${commit_sign:-<unset>}"
print_kv "tag.gpgsign" "${tag_sign:-<unset>}"
print_kv "gpg.ssh.allowedSignersFile" "${allowed_signers_cfg:-<unset>}"

if [ "$gpg_format" = "ssh" ]; then
  print_status ok "git is configured for SSH signing"
else
  print_status fail "git is not configured for SSH signing"
fi

if [ "$commit_sign" = "true" ]; then
  print_status ok "commit signing is enabled"
else
  print_status warn "commit signing is not enabled"
fi

if [ -n "$signing_key" ]; then
  signing_key_path="$(resolve_path "$signing_key")"
  if [ -f "$signing_key_path" ]; then
    print_status ok "configured signing key file exists: $signing_key_path"
  else
    print_status fail "configured signing key file is missing: $signing_key_path"
  fi
else
  print_status fail "user.signingkey is unset"
fi

print_section "Allowed Signers"
if [ -n "$allowed_signers_cfg" ]; then
  allowed_signers_path="$(resolve_path "$allowed_signers_cfg")"
  print_kv "resolved path" "$allowed_signers_path"
  if [ -f "$allowed_signers_path" ]; then
    first_line="$(sed -n '1p' "$allowed_signers_path" 2>/dev/null || true)"
    if [ -n "$first_line" ]; then
      print_status ok "allowed signers file exists"
      print_kv "first entry" "$(trim_newline "$first_line")"
    else
      print_status warn "allowed signers file exists but is empty"
    fi
  else
    print_status fail "allowed signers file is missing"
  fi
else
  print_status fail "gpg.ssh.allowedSignersFile is unset"
fi

print_section "SSH Agent"
print_kv "SSH_AUTH_SOCK" "${SSH_AUTH_SOCK:-<unset>}"
if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
  print_status ok "SSH agent socket is present"
else
  print_status fail "SSH agent socket is missing or not a socket"
fi
agent_probe

print_section "GitHub SSH Transport"
transport_probe

print_section "Commit Signature Verification"
signature_probe

print_section "Classification Guide"
cat <<'EOF'
- Signing config failure: `gpg.format`, `user.signingkey`, or `gpg.ssh.allowedSignersFile` is unset or points at missing files.
- Agent identity-loading failure: `SSH_AUTH_SOCK` exists, but `ssh-add -l` shows no identities or cannot talk to the agent.
- GitHub transport/auth failure: the `ssh -T -o BatchMode=yes git@github.com` probe fails even if signing config is correct.
- Signature verification mismatch: `git log --show-signature` reports missing verification keys or unsigned HEAD; this is separate from transport and agent state.
EOF

print_section "Summary"
print_kv "ok" "$status_ok"
print_kv "warn" "$status_warn"
print_kv "fail" "$status_fail"

if [ "$status_fail" -gt 0 ]; then
  exit 1
fi

exit 0
