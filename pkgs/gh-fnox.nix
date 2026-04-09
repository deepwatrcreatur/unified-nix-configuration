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
      token_file=''${XDG_CONFIG_HOME:-"$HOME/.config"}/git/github-token
      agenix_token_file=''${XDG_DATA_HOME:-"$HOME/.local/share"}/agenix-user-secrets/github-token

      if [ -z "''${GH_TOKEN:-}" ]; then
        if [ -n "''${GITHUB_TOKEN:-}" ]; then
          export GH_TOKEN="$GITHUB_TOKEN"
        elif [ -f "$agenix_token_file" ]; then
          token="$(tr -d '\n' < "$agenix_token_file")"
          if [ -n "$token" ]; then
            export GH_TOKEN="$token"
          fi
        elif [ -f "$token_file" ]; then
          token="$(tr -d '\n' < "$token_file")"
          if [ -n "$token" ]; then
            export GH_TOKEN="$token"
          fi
        else
          token="$(fnox get GITHUB_TOKEN 2>/dev/null || true)"
          if [ -n "$token" ]; then
            export GH_TOKEN="$token"
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
