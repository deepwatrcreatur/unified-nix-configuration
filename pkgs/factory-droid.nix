# pkgs/factory-droid.nix
# Factory.ai Droid CLI (prebuilt binary, patched on NixOS)
#
# Factory publishes both "x64" and "x64-baseline" for Linux. The baseline
# artifact currently appears to be Bun itself, while the "x64" artifact is
# the actual droid CLI. The official installer selects based on AVX2.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  patchelf,
  glibc,
  buildFHSEnv,
  git,
  openssh,
  ripgrep,
  xdg-utils,
}:

let
  version = "0.48.1";
  system = stdenv.hostPlatform.system;
  platform = if stdenv.isDarwin then "darwin" else "linux";
  isX86_64Linux = system == "x86_64-linux";

  hashBySystem = {
    "aarch64-linux" = "sha256-ZujFPpKUASj1xA/gNYxE2brw5ebAGtmyfB9M3mMc24k=";
    "x86_64-darwin" = "sha256-qCt8fS8/IYm53UhOtDF6u831NzgSVbVdYUr7uToEGFE=";
    "aarch64-darwin" = "sha256-M0QYX7u9GHqHcPbL9dR7+vC2QIUxrgN4N2cSAIAmmRE=";
  };

  # Working CLI on modern x86_64 Linux
  srcX64Linux = fetchurl {
    url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64/droid";
    hash = "sha256-gOGbOy9YQibgN8nJRDmOvNs8tVNpgKj86ckzTbGzZ2U=";
  };

  # Kept for completeness / older CPUs (selected at runtime)
  srcX64BaselineLinux = fetchurl {
    url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64-baseline/droid";
    hash = "sha256-5QsvAvmcjVbplJB0JHhqfSKJtoCTAuVXXgj5cu57Q6M=";
  };

  archGeneric = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64-baseline";
  srcGeneric = fetchurl {
    url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform}/${archGeneric}/droid";
    hash = hashBySystem.${system};
  };
in
if isX86_64Linux then
  let
    # The x64 droid binary behaves correctly when executed in an
    # FHS-ish runtime environment (as in the official installer).
    droidUnwrapped = stdenvNoCC.mkDerivation {
      pname = "factory-droid-unwrapped";
      src = srcX64Linux;
      inherit version;
      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        install -m755 "$src" "$out/bin/droid"
        runHook postInstall
      '';
    };
  in
  buildFHSEnv {
    name = "droid";
    runScript = "${droidUnwrapped}/bin/droid";
    targetPkgs = pkgs: with pkgs; [
      git
      openssh
      ripgrep
    ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ xdg-utils ];
    meta = {
      description = "Factory.ai Droid CLI";
      homepage = "https://factory.ai";
      mainProgram = "droid";
      platforms = [ "x86_64-linux" ];
    };
  }
else
  stdenv.mkDerivation {
    pname = "factory-droid";
    src = srcGeneric;
    inherit version;
    dontUnpack = true;

    nativeBuildInputs = [
      makeWrapper
    ] ++ lib.optionals stdenv.isLinux [
      autoPatchelfHook
      patchelf
    ];

    buildInputs = lib.optionals stdenv.isLinux [
      stdenv.cc.cc.lib
      glibc
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      install -m755 "$src" "$out/bin/droid"

      ${lib.optionalString stdenv.isLinux ''
        patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" "$out/bin/droid"
        autoPatchelf "$out/bin/droid" || true
      ''}

      wrapProgram "$out/bin/droid" \
        --prefix PATH : "${lib.makeBinPath ([
          ripgrep
          git
          openssh
        ] ++ lib.optionals stdenv.isLinux [ xdg-utils ])}"

      runHook postInstall
    '';

    meta = {
      description = "Factory.ai Droid CLI";
      homepage = "https://factory.ai";
      mainProgram = "droid";
      platforms = [ "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  }
