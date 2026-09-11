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
  ninja,
  pkg-config,
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
      tesseract
      wl-clipboard
      xdg-utils
    ])
  ];

  meta = {
    description = "Native Wayland screenshot and annotation editor for Omarchy and Hyprland";
    homepage = "https://github.com/tobi/omasnap";
    license = lib.licenses.mit;
    mainProgram = "omasnap";
    platforms = lib.platforms.linux;
  };
})
