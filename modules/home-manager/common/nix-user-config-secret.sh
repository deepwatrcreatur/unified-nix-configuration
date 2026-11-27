# Secret lookup for nix-user-config's activation steps (sourced, bash).
# Tested by checks.x86_64-linux.nix-user-config-secret.
#
# Callers set, before sourcing:
#   NUC_FNOX       fnox binary, or empty when programs.fnox is off
#   NUC_FNOX_CONFIG, NUC_FNOX_AGE_KEY_FILE   fnox's config and identity

# nuc_valid KIND VALUE: does VALUE look like a usable secret of KIND?
# SECURITY: a broken fnox answers with the literal provider name ("age"); an
# error message can land in a token file. Neither may be written to nix.conf
# or the netrc.
nuc_valid() {
  local kind="$1" value="$2"
  case "$value" in
    "" | *[[:space:]]*) return 1 ;;
  esac
  [ "${#value}" -ge 20 ] || return 1
  if [ "$kind" = github ]; then
    case "$value" in
      ghp_* | gho_* | ghu_* | ghs_* | ghr_* | github_pat_*) ;;
      *) return 1 ;;
    esac
  fi
  return 0
}

# nuc_secret KIND FNOX_NAME FILE: print the secret, or nothing.
# Tries fnox first (when enabled and FNOX_NAME is set), then FILE. A value
# that fails nuc_valid is dropped with a warning; the value is never printed
# to stderr.
nuc_secret() {
  local kind="$1" name="$2" file="$3" value=""
  if [ -n "${NUC_FNOX:-}" ] && [ -n "$name" ]; then
    # WHY: --if-missing error, or fnox exits 0 with an empty value; the
    # variable is unset so a token in the environment cannot stand in.
    if value="$(env -u "$name" FNOX_AGE_KEY_FILE="$NUC_FNOX_AGE_KEY_FILE" \
      "$NUC_FNOX" -c "$NUC_FNOX_CONFIG" --if-missing error get "$name" 2>/dev/null)"; then
      if ! nuc_valid "$kind" "$value"; then
        echo "Warning: fnox secret $name does not look like a $kind token; ignoring it" >&2
        value=""
      fi
    else
      value=""
    fi
  fi
  if [ -z "$value" ] && [ -n "$file" ] && [ -f "$file" ]; then
    value="$(cat -- "$file" 2>/dev/null)" || value=""
    if ! nuc_valid "$kind" "$value"; then
      echo "Warning: $file does not hold a valid $kind token; ignoring it" >&2
      value=""
    fi
  fi
  printf '%s' "$value"
}
