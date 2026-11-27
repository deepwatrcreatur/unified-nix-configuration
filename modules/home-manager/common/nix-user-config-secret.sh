# Secret lookup for nix-user-config's activation steps (sourced, bash).
# Tested by checks.x86_64-linux.nix-user-config-secret.
#
# Callers set, before sourcing:
#   NUC_FNOX       fnox binary, or empty when programs.fnox is off
#   NUC_FNOX_CONFIG, NUC_FNOX_AGE_KEY_FILE   fnox's config and identity

# nuc_valid KIND VALUE: does VALUE look like a usable secret of KIND?
# SECURITY: a broken fnox answers with the literal provider name ("age"); an
# error message can land in a token file. Neither may be written to nix.conf
# or the netrc. Any secret: one word, not the placeholder. KIND github also
# needs a GitHub token prefix and a token's length.
nuc_valid() {
  local kind="$1" value="$2"
  case "$value" in
    "" | *[[:space:]]* | age) return 1 ;;
  esac
  if [ "$kind" = github ]; then
    [ "${#value}" -ge 20 ] || return 1
    case "$value" in
      ghp_* | gho_* | ghu_* | ghs_* | ghr_* | github_pat_*) ;;
      *) return 1 ;;
    esac
  fi
  return 0
}

# nuc_secret KIND FNOX_NAME FILE: print the secret, or nothing.
# WHY: FILE first. It is the seed source (agenix user secret), so it is
# current after a rotation, while fnox keeps the value it was seeded with.
# fnox (when enabled and FNOX_NAME is set) covers hosts without the file.
# A value that fails nuc_valid is dropped with a warning that never shows it.
nuc_secret() {
  local kind="$1" name="$2" file="$3" value=""
  if [ -n "$file" ] && [ -f "$file" ]; then
    value="$(cat -- "$file" 2>/dev/null)" || value=""
    if ! nuc_valid "$kind" "$value"; then
      echo "Warning: $file does not hold a valid $kind secret; ignoring it" >&2
      value=""
    fi
  fi
  if [ -z "$value" ] && [ -n "${NUC_FNOX:-}" ] && [ -n "$name" ]; then
    # WHY: --if-missing error, or fnox exits 0 with an empty value; the
    # variable is unset so a token in the environment cannot stand in.
    if value="$(env -u "$name" FNOX_AGE_KEY_FILE="$NUC_FNOX_AGE_KEY_FILE" \
      "$NUC_FNOX" -c "$NUC_FNOX_CONFIG" --if-missing error get "$name" 2>/dev/null)"; then
      if ! nuc_valid "$kind" "$value"; then
        echo "Warning: fnox secret $name does not look like a valid $kind secret; ignoring it" >&2
        value=""
      fi
    else
      value=""
    fi
  fi
  printf '%s' "$value"
}
