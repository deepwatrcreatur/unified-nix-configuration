# pkgs/cmux-tui.nix
# cmux-tui — terminal multiplexer TUI backed by libghostty-vt for AI coding agents
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.9.9";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/cmux-tui-linux-x64/-/cmux-tui-linux-x64-${version}.tgz";
      hash = "sha256-CJk/vuF0lK4wMvX4fLP7oVU6TCbfpwlkUpjcJdN70sg=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/cmux-tui-linux-arm64/-/cmux-tui-linux-arm64-${version}.tgz";
      hash = "sha256-WQORcbw19P8uqTiNxsSxMN61FFGf+v22Kw+rx5VIHjc=";
    };
    aarch64-darwin = {
      url = "https://registry.npmjs.org/cmux-tui-darwin-arm64/-/cmux-tui-darwin-arm64-${version}.tgz";
      hash = "sha256-RGgJJjoO+kuPz6jPJi6dQIXlkiobORoMNpnlQQ0L+To=";
    };
    x86_64-darwin = {
      url = "https://registry.npmjs.org/cmux-tui-darwin-x64/-/cmux-tui-darwin-x64-${version}.tgz";
      hash = "sha256-4Bw05zD/cHLlI2xPhe6qQtsYiiXbd6/BKmFm6q2IX60=";
    };
  };

  srcInfo =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported platform for cmux-tui: ${stdenvNoCC.hostPlatform.system}");

in
stdenvNoCC.mkDerivation {
  pname = "cmux-tui";
  inherit version;

  src = fetchurl {
    inherit (srcInfo) url hash;
  };

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    cd package
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 bin/cmux-tui "$out/bin/cmux-tui"
    ln -s "$out/bin/cmux-tui" "$out/bin/cmux"
    runHook postInstall
  '';

  meta = {
    description = "cmux-tui — terminal multiplexer TUI for AI coding agents backed by libghostty-vt";
    homepage = "https://github.com/manaflow-ai/cmux";
    license = lib.licenses.mit;
    mainProgram = "cmux-tui";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
