# pkgs/orca-ide.nix
# Orca - The Agent Development Environment (ADE) for coding agents
{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "orca-ide";
  version = "1.4.239";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-nBC1SLUw4I/BI6RnRqo7+mbhXjSfqQFKdaKt3FxPJs0=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      libsecret
      libnotify
      nss
      nspr
      glib
      gtk3
      mesa
      alsa-lib
    ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/orca-ide.png $out/share/icons/hicolor/512x512/apps/orca-ide.png
    install -m 444 -D ${appimageContents}/orca-ide.desktop $out/share/applications/orca-ide.desktop
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail "Exec=AppRun %U" "Exec=orca-ide %U" \
      --replace-fail "Categories=Utility;" "Categories=Development;IDE;Utility;"

    ln -s $out/bin/orca-ide $out/bin/orca
  '';

  meta = with lib; {
    description = "Orca - The Agent Development Environment (ADE) for coding agents";
    homepage = "https://www.onorca.dev";
    mainProgram = "orca-ide";
    platforms = [ "x86_64-linux" ];
  };
}
