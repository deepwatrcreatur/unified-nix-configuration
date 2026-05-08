{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "iventoy-free";
  version = "1.0.26";

  src = fetchurl {
    url = "https://github.com/ventoy/PXE/releases/download/v${version}/iventoy-${version}-linux-free.tar.gz";
    hash = "sha256-B/8JyTDHmw5OSCTAm34qYhlJh3e2vih+9NusgG8ofa8=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/iventoy"
    cp -a . "$out/share/iventoy"

    runHook postInstall
  '';

  meta = {
    description = "iVentoy Free Edition PXE server";
    homepage = "https://www.iventoy.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
