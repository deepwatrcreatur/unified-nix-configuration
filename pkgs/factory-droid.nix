{
  prev,
  nixpkgsLib,
}:
let
  version = "0.48.1";
  system = prev.stdenv.hostPlatform.system;
  platform = if prev.stdenv.isDarwin then "darwin" else "linux";
  isX86_64Linux = system == "x86_64-linux";

  hashBySystem = {
    "aarch64-linux" = "sha256-ZujFPpKUASj1xA/gNYxE2brw5ebAGtmyfB9M3mMc24k=";
    "x86_64-darwin" = "sha256-qCt8fS8/IYm53UhOtDF6u831NzgSVbVdYUr7uToEGFE=";
    "aarch64-darwin" = "sha256-M0QYX7u9GHqHcPbL9dR7+vC2QIUxrgN4N2cSAIAmmRE=";
  };

  srcX64Linux = prev.fetchurl {
    url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64/droid";
    hash = "sha256-gOGbOy9YQibgN8nJRDmOvNs8tVNpgKj86ckzTbGzZ2U=";
  };

  srcGeneric = prev.fetchurl {
    url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform}/${if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x64-baseline"}/droid";
    hash = hashBySystem.${system};
  };
in
if isX86_64Linux then
  let
    droidUnwrapped = prev.stdenvNoCC.mkDerivation {
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
  prev.buildFHSEnv {
    name = "droid";
    runScript = "${droidUnwrapped}/bin/droid";
    targetPkgs =
      pkgs:
      with pkgs;
      [
        git
        openssh
        ripgrep
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ xdg-utils ];
    meta = {
      description = "Factory.ai Droid CLI";
      homepage = "https://factory.ai";
      mainProgram = "droid";
      platforms = [ "x86_64-linux" ];
    };
  }
else
  prev.stdenv.mkDerivation {
    pname = "factory-droid";
    src = srcGeneric;
    inherit version;
    dontUnpack = true;

    nativeBuildInputs = [ prev.makeWrapper ] ++ nixpkgsLib.optionals prev.stdenv.isLinux [
      prev.autoPatchelfHook
      prev.patchelf
    ];
    buildInputs = nixpkgsLib.optionals prev.stdenv.isLinux [
      prev.stdenv.cc.cc.lib
      prev.glibc
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      install -m755 "$src" "$out/bin/droid"

      if [ "${if prev.stdenv.isLinux then "1" else "0"}" = "1" ]; then
        patchelf --set-interpreter "$(cat ${prev.stdenv.cc}/nix-support/dynamic-linker)" "$out/bin/droid"
        autoPatchelf "$out/bin/droid" || true
      fi

      wrapProgram "$out/bin/droid" \
        --prefix PATH : "${
          prev.lib.makeBinPath (
            [
              prev.ripgrep
              prev.git
              prev.openssh
            ]
            ++ prev.lib.optionals prev.stdenv.isLinux [ prev.xdg-utils ]
          )
        }"

      runHook postInstall
    '';

    meta = {
      description = "Factory.ai Droid CLI";
      homepage = "https://factory.ai";
      mainProgram = "droid";
      platforms = [
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  }
