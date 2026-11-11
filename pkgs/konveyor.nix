{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  extra-cmake-modules,
  pkg-config,
  wrapQtAppsHook,
  # Qt6
  qtbase,
  qtdeclarative,
  qtshadertools,
  # KDE Frameworks & Plasma
  kwin,
  kdecoration,
  kcoreaddons,
  kglobalaccel,
  kconfig,
  kcolorscheme,
  knotifications,
  ki18n,
  kwindowsystem,
  libplasma,
  kcmutils,
  kservice,
  # System libraries
  libxkbcommon,
  pipewire,
  libxcb,
  xcbutilwm,
  libepoxy,
  libdrm,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "konveyor";
  version = "0.1.0-unstable-2026-11-04";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "eadb74d9cc6c27358011b44ceebdd7171b5a40ba";
    hash = "sha256-RYWlFIDaGaMHo/E9b/M7wxNJTA+CF2zwk5a7G62CsY8=";
  };

  patches = [
    ./konveyor-kwin-6.6.patch
  ];

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    # Qt6
    qtbase
    qtdeclarative
    qtshadertools

    # KDE Frameworks & Plasma
    kwin
    kdecoration
    kcoreaddons
    kglobalaccel
    kconfig
    kcolorscheme
    knotifications
    ki18n
    kwindowsystem
    libplasma
    kcmutils
    kservice

    # System libraries
    libxkbcommon
    pipewire
    libxcb
    xcbutilwm
    libepoxy
    libdrm
    wayland
  ];

  cmakeFlags = [
    "-DKONVEYOR_BUILD_TESTS=OFF"
    "-DCMAKE_COMPILE_WARNING_AS_ERROR=OFF"
  ];

  meta = {
    description = "Scrolling column-based tiling manager for KDE Plasma 6 (Wayland)";
    homepage = "https://github.com/DevL0rd/Konveyor";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
