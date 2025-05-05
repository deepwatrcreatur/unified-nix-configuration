{ stdenv, ncurses }:

stdenv.mkDerivation {
  pname = "terminfo-extra";
  version = "1.0";
  src = ../terminfo;

  buildInputs = [ ncurses ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/terminfo
    cp -rT $src $out/share/terminfo
    runHook postInstall
  '';
}
