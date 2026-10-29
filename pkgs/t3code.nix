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

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/bin
    cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true

    mv $out/bin/t3code $out/bin/.t3code-unwrapped

    cat <<EOF > $out/bin/t3code
#!/usr/bin/env bash
if [ "\$ELECTRON_RUN_AS_NODE" = "1" ] || [[ "\$1" == *.js ]] || [[ "\$1" == *.mjs ]]; then
  export ELECTRON_RUN_AS_NODE=1
  exec "$out/bin/.t3code-unwrapped" "\$@"
fi

has_store=false
for arg in "\$@"; do
  case "\$arg" in
    --password-store*)
      has_store=true
      break
      ;;
  esac
done

if [ "\$has_store" = "false" ]; then
  exec "$out/bin/.t3code-unwrapped" --password-store=basic "\$@"
else
  exec "$out/bin/.t3code-unwrapped" "\$@"
fi
EOF
    chmod +x $out/bin/t3code

    cat <<EOF > $out/bin/t3
#!/usr/bin/env bash
export ELECTRON_RUN_AS_NODE=1
exec "$out/bin/.t3code-unwrapped" "${appimageContents}/resources/app.asar/apps/server/dist/bin.mjs" "\$@"
EOF
    chmod +x $out/bin/t3
    ln -s $out/bin/t3 $out/bin/t3code-server

    cat <<EOF > $out/share/applications/t3code.desktop
[Desktop Entry]
Name=T3 Code
Exec=t3code %U
Icon=t3code
Type=Application
Categories=Development;IDE;
Comment=Agentic AI Coding Harness
Terminal=false
MimeType=x-scheme-handler/t3code;x-scheme-handler/t3code-dev;
EOF

    cat <<EOF > $out/share/applications/t3code-url-handler.desktop
[Desktop Entry]
Type=Application
Name=T3 Code (Alpha)
Exec=t3code %U
Terminal=false
NoDisplay=true
StartupNotify=false
MimeType=x-scheme-handler/t3code;x-scheme-handler/t3code-dev;
EOF
  '';

  meta = with lib; {
    description = "T3 Code - Agentic AI coding harness by Theo Browne (@t3dotgg)";
    homepage = "https://github.com/pingdotgg/t3code";
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
  };
}
