{
  lib,
  stdenv,
  bash,
  cmake,
  coreutils,
  fetchFromGitHub,
  grim,
  hyprland,
  kdePackages,
  makeWrapper,
  ninja,
  pkg-config,
  slurp,
  tesseract,
  wayland,
  wayland-protocols,
  wayland-scanner,
  wl-clipboard,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "omasnap";
  version = "1.20.1";

  src = fetchFromGitHub {
    owner = "tobi";
    repo = "omasnap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ym9nPFOmligiXbc5ls4/PjZ9UGpoLTHlCZWJbTP0wVo=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "/usr/share/wayland-protocols" \
        "${wayland-protocols}/share/wayland-protocols"
    if [ -f tests/transform-smoke.cpp ]; then
      substituteInPlace tests/transform-smoke.cpp \
        --replace-fail "/usr/bin/env bash" "${coreutils}/bin/env bash" || true
    fi
  '';

  nativeBuildInputs = [
    cmake
    kdePackages.wrapQtAppsHook
    makeWrapper
    ninja
    pkg-config
    wayland
    wayland-scanner
  ];

  buildInputs = [
    kdePackages.layer-shell-qt
    kdePackages.qtbase
    kdePackages.qttools
    wayland
    wayland-protocols
  ];

  nativeCheckInputs = [
    bash
    coreutils
    tesseract
  ];

  postInstall = ''
    if [ -f $out/share/applications/omasnap.desktop ]; then
      substituteInPlace $out/share/applications/omasnap.desktop \
        --replace-fail "NoDisplay=true" "NoDisplay=false"
    fi

    mv $out/bin/omasnap $out/bin/.omasnap-binary

    cat <<'EOF' > $out/bin/omasnap
#!/usr/bin/env bash
set -e

# If arguments are passed, or if hyprctl is active, run the main binary directly.
if [ $# -gt 0 ] || ${hyprland}/bin/hyprctl monitors -j >/dev/null 2>&1; then
  exec @out@/bin/.omasnap-binary "$@"
fi

# Fallback for non-Hyprland Wayland sessions (GNOME, COSMIC, Sway, etc.)
tmp_file="$(mktemp --suffix=.png /tmp/omasnap-XXXXXX)"

if ${slurp}/bin/slurp -b "#00000080" -c "#ffffff" > "$tmp_file.region" 2>/dev/null; then
  region="$(cat "$tmp_file.region")"
  rm -f "$tmp_file.region"
  if [ -n "$region" ]; then
    ${grim}/bin/grim -g "$region" "$tmp_file" && exec @out@/bin/.omasnap-binary --file "$tmp_file"
    exit 0
  fi
fi

# Fullscreen fallback if region selection was skipped or cancelled
if ${grim}/bin/grim "$tmp_file" 2>/dev/null; then
  exec @out@/bin/.omasnap-binary --file "$tmp_file"
fi
EOF

    substituteInPlace $out/bin/omasnap --replace-fail "@out@" "$out"
    chmod +x $out/bin/omasnap
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    QT_QPA_PLATFORM=offscreen ./omasnap-smoke "$TMPDIR/omasnap-smoke"
    runHook postCheck
  '';

  qtWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      grim
      hyprland
      slurp
      tesseract
      wl-clipboard
      xdg-utils
    ])
  ];

  meta = {
    description = "Native Wayland screenshot and annotation editor for Hyprland, GNOME, and COSMIC";
    homepage = "https://github.com/tobi/omasnap";
    license = lib.licenses.mit;
    mainProgram = "omasnap";
    platforms = lib.platforms.linux;
  };
})
