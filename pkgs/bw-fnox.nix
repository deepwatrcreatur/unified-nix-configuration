{
  lib,
  symlinkJoin,
  writeShellApplication,
  bitwarden-cli,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "bw-fnox";

    runtimeInputs = [
      bitwarden-cli
      fnox
    ];

    text = ''
      set -euo pipefail

      session_file=''${XDG_CONFIG_HOME:-"$HOME/.config"}/sops/BW_SESSION

      if [ -z "''${BW_SESSION:-}" ]; then
        session="$(fnox get BW_SESSION 2>/dev/null || true)"
        if [ -n "$session" ]; then
          export BW_SESSION="$session"
        elif [ -f "$session_file" ]; then
          session="$(tr -d '\n' < "$session_file")"
          export BW_SESSION="$session"
        fi
      fi

      exec bw "$@"
    '';
  };
in
symlinkJoin {
  name = "bw-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/bw-fnox" "$out/bin/bw"
  '';

  meta = {
    description = "Bitwarden CLI wrapper that sources BW_SESSION via fnox with file fallback";
    homepage = "https://bitwarden.com/help/cli/";
    mainProgram = "bw";
    platforms = bitwarden-cli.meta.platforms or lib.platforms.all;
  };
}
