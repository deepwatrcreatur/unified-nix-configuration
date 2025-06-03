
# flake-modules/version-utils.nix
# This file provides utility functions, e.g., for generating version strings from Git sources.

{ lib }: # Takes nixpkgs.lib as an argument

{
  # Generates a version string like "YYYYMMDD-abcdefg" from a source derivation
  # fetched by fetchFromGitHub (or similar that provides src.passthru.date and src.passthru.rev).
  generateVersionFromGitSource = src:
    let
      # fetchFromGitHub sets src.passthru.date to an ISO8601 commit date string
      # and src.passthru.rev to the full commit hash.
      # Provide fallbacks in case these attributes are unexpectedly missing.
      commitDateIso = src.passthru.date or "1970-01-01T00:00:00Z";
      commitHash = src.passthru.rev or "0000000";

      # Format date from "YYYY-MM-DDTHH:mm:ssZ" to "YYYYMMDD"
      # 1. Take the first 10 chars: "YYYY-MM-DD"
      # 2. Remove the hyphens: "YYYYMMDD"
      formattedDate = lib.strings.remove ["-"] [""] (builtins.substring 0 10 commitDateIso);

      # Get short commit hash (first 7 chars)
      shortCommitHash = lib.substring 0 7 commitHash;
    in
    "${formattedDate}-${shortCommitHash}";
}
