# pkgs/t3code.nix
# T3 Code - Agentic AI Coding GUI Harness by Theo Browne (@t3dotgg)
{ appimageTools, fetchurl, lib }:

let
  pname = "t3code";
  version = "0.0.32";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-SS7ctI7vlzCfNMS3CoEhuGfDronCBowuKLs5Oo2CLCI=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libsecret
    libnotify
    nss
    nspr
    glib
    gtk3
  ];

  extraInstallPhase = ''
    mkdir -p $out/share/applications
    cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true

    cat <<EOF > $out/share/applications/t3code.desktop
[Desktop Entry]
Name=T3 Code
Exec=t3code %U
Icon=t3code
Type=Application
Categories=Development;IDE;
Comment=Agentic AI Coding Harness
Terminal=false
EOF
  '';

  meta = with lib; {
    description = "T3 Code - Agentic AI coding harness by Theo Browne (@t3dotgg)";
    homepage = "https://github.com/pingdotgg/t3code";
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
  };
}
