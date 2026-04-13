# pkgs/repo-updater.nix
# repo_updater (ru) — parallelized multi-repo sync and review CLI
# https://github.com/Dicklesworthstone/repo_updater
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  git,
  gh,
  gum,
  jq,
  curl,
  gnused,
  gnugrep,
  findutils,
}:

stdenvNoCC.mkDerivation {
  pname = "repo-updater";
  version = "unstable-2025-04-13";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "repo_updater";
    rev = "8e069241b67e164bd9018271391d20cc822d40d2";
    hash = "sha256-V9ysGie1SrSrSQHE2ressqAK85J9yleFUHUAbOYG0Co=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m 755 ru "$out/bin/ru"

    # Replace shebang with the Nix-managed bash.
    sed -i "1s|.*|#!${bash}/bin/bash|" "$out/bin/ru"

    runHook postInstall
  '';

  postInstall = ''
    wrapProgram "$out/bin/ru" \
      --prefix PATH : "${lib.makeBinPath [
        bash
        coreutils
        git
        gh
        gum
        jq
        curl
        gnused
        gnugrep
        findutils
      ]}"
  '';

  meta = {
    description = "Beautiful, automation-friendly CLI for synchronizing GitHub repositories";
    longDescription = ''
      repo_updater (ru) keeps dozens of local git repos in sync with a single
      command. Features: clone missing repos, pull updates, detect conflicts,
      JSON output for scripting, and meaningful exit codes (0-5).

      Commands: sync (default), status, init, add, list, doctor, prune, review.
    '';
    homepage = "https://github.com/Dicklesworthstone/repo_updater";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "ru";
  };
}
