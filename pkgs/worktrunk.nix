{ lib, stdenvNoCC, fetchurl, xz }:

let
  version = "0.57.0";
  target =
    {
      x86_64-linux = {
        asset = "worktrunk-x86_64-unknown-linux-musl.tar.xz";
        hash = "sha256-ltacGo3WLASfS7IPuhd9dISHDUGiYBZfGk+UmjWVH08=";
      };
      aarch64-linux = {
        asset = "worktrunk-aarch64-unknown-linux-musl.tar.xz";
        hash = "sha256-i6d6yitA7x8IhpzJUxs9WTsFY+d2UAAvdeLs9X5AjoE=";
      };
      x86_64-darwin = {
        asset = "worktrunk-x86_64-apple-darwin.tar.xz";
        hash = "sha256-MO3VlxMyWsMVc1J+NWshmALjZVPmgxPFL8sszKbGFws=";
      };
      aarch64-darwin = {
        asset = "worktrunk-aarch64-apple-darwin.tar.xz";
        hash = "sha256-V0ZxCKoc1zIGSzHD7qac1wsDRWAWCytNH7FYEJxHVJ0=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system for worktrunk: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "worktrunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/max-sixty/worktrunk/releases/download/v${version}/${target.asset}";
    inherit (target) hash;
  };

  nativeBuildInputs = [ xz ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    tar -xJf "$src" -C "$TMPDIR"
    install -m755 "$TMPDIR/wt" "$out/bin/wt"

    if [ -f "$TMPDIR/git-wt" ]; then
      install -m755 "$TMPDIR/git-wt" "$out/bin/git-wt"
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "A CLI for Git worktree management, designed for parallel AI agent workflows";
    homepage = "https://github.com/max-sixty/worktrunk";
    license = with licenses; [
      mit
      asl20
    ];
    mainProgram = "wt";
    platforms = builtins.attrNames {
      x86_64-linux = true;
      aarch64-linux = true;
      x86_64-darwin = true;
      aarch64-darwin = true;
    };
  };
}
