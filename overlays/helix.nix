# overlays/helix.nix
# This function takes `self` (the final package set after all overlays)
# and `super` (the package set before this overlay is applied).
self: super: {
  helix-from-src = super.rustPlatform.buildRustPackage rec {
    pname = "helix-from-src";
    # The version will be dynamically set based on git information
    # For example: "20250603-abcdefg"
    version = "${super.lib.substring 0 8 src.revDate}-${super.lib.substring 0 7 src.rev}";

    src = super.fetchFromGitHub {
      owner = "helix-editor";
      repo = "helix";
      # IMPORTANT: Replace with the actual commit hash you want to build
      # Get the latest commit from master:
      # git ls-remote https://github.com/helix-editor/helix.git HEAD | awk '{ print $1 }'
      rev = "1ea9050a5e12a1bc3eeb4b81022f427688c5ffa9";

      # IMPORTANT: After setting 'rev', build once with a dummy sha256.
      # Nix will fail and output the correct sha256. Update it here.
      # For example, use a dummy like: "0000000000000000000000000000000000000000000000000000"
      # or super.lib.fakeSha256
      sha256 = "PUT_CORRECT_SHA256_HERE";
      fetchSubmodules = true; # Helix uses submodules for tree-sitter grammars
    };

    cargoLock = {
      # Helix commits its Cargo.lock file, so we can use it directly.
      lockFile = src + "/Cargo.lock";
    };

    # Build dependencies
    nativeBuildInputs = with super; [
      pkg-config
    ];
    # Runtime dependencies (especially for different platforms)
    buildInputs = with super; []
      ++ super.lib.optionals stdenv.isDarwin [ libiconv darwin.apple_sdk.frameworks.SystemConfiguration ];


    meta = with super.lib; {
      description = "Helix editor compiled from source (for command expansion)";
      homepage = "https://helix-editor.com/";
      license = licenses.mpl20;
      # maintainers = with maintainers; [  ]; # Optional
      platforms = platforms.unix;
    };
  };
}
