{
  lib,
  symlinkJoin,
  writeShellApplication,
  opencode,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "opencode-zai";

    runtimeInputs = [
      opencode
      fnox
    ];

    text = ''
      if [ -z "''${Z_AI_API_KEY:-}" ]; then
        _key=""
        if [ -z "$_key" ]; then
          _key="$(fnox get Z_AI_API_KEY 2>/dev/null || true)"
        fi
        if [ -n "$_key" ]; then
          export Z_AI_API_KEY="$_key"
        fi
      fi

      exec opencode "$@"
    '';
  };
in
symlinkJoin {
  name = "opencode-zai";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/opencode-zai" "$out/bin/opencode"
  '';

  meta = {
    description = "OpenCode CLI wrapper that sources Z_AI_API_KEY via fnox, using repo-managed opencode version";
    homepage = "https://opencode.ai";
    mainProgram = "opencode";
    platforms = opencode.meta.platforms or lib.platforms.all;
  };
}
