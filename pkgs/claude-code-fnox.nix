{
  lib,
  symlinkJoin,
  writeShellApplication,
  claude-code,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "claude-code-fnox";

    runtimeInputs = [
      claude-code
      fnox
    ];

    text = ''
      if [ -z "''${ANTHROPIC_API_KEY:-}" ]; then
        _key=""
        if [ -z "$_key" ]; then
          _key="$(fnox get ANTHROPIC_API_KEY 2>/dev/null || true)"
        fi
        if [ -n "$_key" ]; then
          export ANTHROPIC_API_KEY="$_key"
        fi
      fi

      exec claude-code "$@"
    '';
  };
in
symlinkJoin {
  name = "claude-code-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/claude-code-fnox" "$out/bin/claude-code"
  '';

  meta = {
    description = "Claude Code CLI wrapper that sources ANTHROPIC_API_KEY via fnox";
    homepage = "https://code.claude.com";
    mainProgram = "claude-code";
    platforms = claude-code.meta.platforms or lib.platforms.all;
  };
}
