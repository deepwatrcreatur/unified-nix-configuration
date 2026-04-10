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
      agenix_token_file="$HOME/.local/share/agenix-user-secrets/github-token"
      token_file=''${XDG_CONFIG_HOME:-"$HOME/.config"}/git/github-token

      if [ -z "''${GH_TOKEN:-}" ]; then
        _token=""
        if [ -n "''${GITHUB_TOKEN:-}" ]; then
          _token="$(printf '%s' "''${GITHUB_TOKEN}" | tr -d '[:space:]')"
        fi
        if [ -z "$_token" ] && [ -f "$agenix_token_file" ]; then
          _token="$(tr -d '[:space:]' < "$agenix_token_file")"
        fi
        if [ -z "$_token" ] && [ -f "$token_file" ]; then
          _token="$(tr -d '[:space:]' < "$token_file")"
        fi
        if [ -z "$_token" ]; then
          _token="$(fnox get GITHUB_TOKEN 2>/dev/null || true)"
        fi
        if [ -n "$_token" ]; then
          export GH_TOKEN="$_token"
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
    description = "GitHub CLI wrapper that prefers managed token files before fnox fallback";
    homepage = "https://github.com/cli/cli";
    mainProgram = "gh";
    platforms = gh.meta.platforms or lib.platforms.all;
  };
}
