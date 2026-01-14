{
  config,
  pkgs,
  lib,
  ...
}:

let
  factoryDroid =
    let
      version = "0.48.1";
      platform = if pkgs.stdenv.isDarwin then "darwin" else "linux";
      arch =
        if pkgs.stdenv.hostPlatform.isAarch64 then
          "arm64"
        else
          # Use baseline for x86_64 to avoid AVX2 assumptions.
          "x64-baseline";

      hash =
        {
          "x86_64-linux" = "sha256-5QsvAvmcjVbplJB0JHhqfSKJtoCTAuVXXgj5cu57Q6M=";
          "aarch64-linux" = "sha256-ZujFPpKUASj1xA/gNYxE2brw5ebAGtmyfB9M3mMc24k=";
          "x86_64-darwin" = "sha256-qCt8fS8/IYm53UhOtDF6u831NzgSVbVdYUr7uToEGFE=";
          "aarch64-darwin" = "sha256-M0QYX7u9GHqHcPbL9dR7+vC2QIUxrgN4N2cSAIAmmRE=";
        }
        .${pkgs.stdenv.hostPlatform.system};

      src = pkgs.fetchurl {
        url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform}/${arch}/droid";
        inherit hash;
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "factory-droid";
      inherit version src;
      dontUnpack = true;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        install -m755 "$src" "$out/bin/droid"
        wrapProgram "$out/bin/droid" \
          --prefix PATH : "${
            pkgs.lib.makeBinPath (
              [
                pkgs.ripgrep
                pkgs.git
                pkgs.openssh
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.xdg-utils ]
            )
          }"
        runHook postInstall
      '';
      meta = {
        description = "Factory.ai Droid CLI";
        homepage = "https://factory.ai";
        mainProgram = "droid";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      };
    };

  # Base packages that should always be available
  basePackages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
    opencode
    factoryDroid
  ];
in
{
  home.packages = basePackages;
}
