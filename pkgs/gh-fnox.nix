{
  lib,
  symlinkJoin,
  writeShellApplication,
  gh,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "gh-fnox";

    runtimeInputs = [
      gh
      fnox
    ];

    text = ''
      agenix_token_file=''${XDG_DATA_HOME:-"$HOME/.local/share"}/agenix-user-secrets/github-token
      token_file=''${XDG_CONFIG_HOME:-"$HOME/.config"}/git/github-token

      github_token_is_sane() {
        local token="$1"

        [ -n "$token" ] || return 1
        case "$token" in
          *[[:space:]]*) return 1 ;;
          ghp_*|gho_*|ghu_*|ghs_*|ghr_*|github_pat_*) ;;
          *) return 1 ;;
        esac

        return 0
      }

      load_token_from_file_if_sane() {
        local candidate="$1"
        local token=""

        [ -f "$candidate" ] || return 1
        token="$(tr -d '\n' < "$candidate")"
        github_token_is_sane "$token" || return 1
        printf '%s' "$token"
      }

      if [ -z "''${GH_TOKEN:-}" ]; then
        if [ -n "''${GITHUB_TOKEN:-}" ] && github_token_is_sane "$GITHUB_TOKEN"; then
          export GH_TOKEN="$GITHUB_TOKEN"
        else
          token="$(load_token_from_file_if_sane "$agenix_token_file" || true)"
          if [ -n "$token" ]; then
            export GH_TOKEN="$token"
          else
            token="$(load_token_from_file_if_sane "$token_file" || true)"
            if [ -n "$token" ]; then
              export GH_TOKEN="$token"
            else
              token="$(fnox get GITHUB_TOKEN 2>/dev/null || true)"
              if github_token_is_sane "$token"; then
                export GH_TOKEN="$token"
              fi
            fi
          fi
        fi
      fi

      exec gh "$@"
    '';
  };
in
symlinkJoin {
  name = "gh-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/gh-fnox" "$out/bin/gh"
  '';

  meta = {
    description = "GitHub CLI wrapper that sources GH_TOKEN via fnox with file fallback";
    homepage = "https://github.com/cli/cli";
    mainProgram = "gh";
    platforms = gh.meta.platforms or lib.platforms.all;
  };
}
