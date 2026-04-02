{
  lib,
  symlinkJoin,
  writeShellApplication,
  attic-client,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "attic-fnox";

    runtimeInputs = [
      attic-client
      fnox
    ];

    text = ''
      token_file=''${XDG_CONFIG_HOME:-"$HOME/.config"}/sops/attic-client-token
      token=""

      get_token() {
        local resolved=""
        resolved="$(fnox get ATTIC_CLIENT_JWT_TOKEN 2>/dev/null || true)"
        if [ -n "$resolved" ]; then
          printf '%s' "$resolved"
          return 0
        fi

        if [ -f "$token_file" ]; then
          tr -d '\n' < "$token_file"
          return 0
        fi

        return 1
      }

      if [ "$#" -ge 1 ] && [ "$1" = "login" ]; then
        if [ "$#" -eq 3 ]; then
          token="$(get_token || true)"
          if [ -n "$token" ]; then
            exec attic login "$2" "$3" "$token"
          fi
        fi
      fi

      exec attic "$@"
    '';
  };
in
symlinkJoin {
  name = "attic-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/attic-fnox" "$out/bin/attic"
  '';

  meta = {
    description = "Attic CLI wrapper that can source the login token via fnox";
    homepage = "https://github.com/zhaofengli/attic";
    mainProgram = "attic";
    platforms = attic-client.meta.platforms or lib.platforms.all;
  };
}
