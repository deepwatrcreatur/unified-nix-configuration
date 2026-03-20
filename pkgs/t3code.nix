# pkgs/t3code.nix
# T3Code - AI code editor
{ stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "t3code";
  version = "0.0.10";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v0.0.10/T3-Code-0.0.10-x86_64.AppImage";
    hash = "sha256-0zycpxdq3q808ih90h8ad3agvldw305y6ndmjwa8zj097rmfrhyd";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 "$src" "$out/bin/t3code"
    runHook postInstall
  '';

  meta = {
    description = "T3Code AI code editor";
    homepage = "https://github.com/pingdotgg/t3code";
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
  };
}
