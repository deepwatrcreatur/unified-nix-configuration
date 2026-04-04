{
  lib,
  symlinkJoin,
  writeShellApplication,
  factory-droid,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "factory-droid-fnox";

    runtimeInputs = [
      factory-droid
      fnox
    ];

    text = ''
      # Inject FACTORY_API_KEY if not already set
      if [ -z "''${FACTORY_API_KEY:-}" ]; then
        key="$(fnox get FACTORY_API_KEY 2>/dev/null || true)"
        if [ -n "$key" ]; then
          export FACTORY_API_KEY="$key"
        fi
      fi

      exec droid "$@"
    '';
  };
in
symlinkJoin {
  name = "factory-droid-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/factory-droid-fnox" "$out/bin/droid"
  '';

  meta = {
    description = "Factory.ai Droid CLI wrapper that sources FACTORY_API_KEY via fnox";
    homepage = "https://factory.ai";
    mainProgram = "droid";
    platforms = factory-droid.meta.platforms or lib.platforms.all;
  };
}
