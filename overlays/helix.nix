# overlays/helix.nix
self: super: # self is the final package set, super is the one before this overlay
let
  versionUtils = import ../flake-modules/version-utils.nix { lib = super.lib; };

  helixFromSrcRaw = super.rustPlatform.buildRustPackage rec {
    pname = "helix-from-src-raw"; # Changed pname slightly to avoid potential name collision if not careful
    # Or keep pname = "helix-from-src" and ensure the wrapper has a distinct name in the final pkgs set.

    src = super.fetchFromGitHub {
      owner = "helix-editor";
      repo = "helix";
      rev = "1ea9050a5e12a1bc3eeb4b81022f427688c5ffa9";
      sha256 = "KWpXXXciUDJp2DitQWT8MNzhECBuHA2SRPz51t0bZG0=";
      fetchSubmodules = true;
    };

    version = versionUtils.generateVersionFromGitSource src;

    cargoLock = {
      lockFile = src + "/Cargo.lock";
    };

    nativeBuildInputs = with super; [
      pkg-config
      git
      cacert
    ];

    buildInputs = with super; []
      ++ super.lib.optionals stdenv.isDarwin [ libiconv darwin.apple_sdk.frameworks.SystemConfiguration ];

    __impure = true; # For network access during build

    GIT_SSL_CAINFO = "${super.cacert}/etc/ssl/certs/ca-bundle.crt";

    meta = with super.lib; {
      description = "Helix editor compiled from source (for command expansion) - Raw Build";
      homepage = "https://helix-editor.com/";
      license = licenses.mpl20;
      platforms = platforms.unix;
    };
  };

  # --- The new wrapper script derivation ---
  # This wrapper will be "pure" in its construction, but calls the impurely built helix.
  helixWrappedForHm = super.writeShellScriptBin "hx-hm-wrapper" ''
    #!${super.runtimeShell}
    # This script simply executes the real hx binary from your impurely built package.
    # The path to helixFromSrcRaw will be "baked in" by Nix.
    exec "${helixFromSrcRaw}/bin/hx" "$@"
  '';

in
{
  # Expose the raw build if you ever need to refer to it directly
  helix-from-src-raw = helixFromSrcRaw;

  # This is the package Home Manager should use.
  # named `helix-from-src` so Home Manager config doesn't need to change `package = pkgs.helix-from-src;`
  # if it was already pointing to that.
  # or can name this `helix-wrapped` and update HM config.
  helix-from-src = helixWrappedForHm;

  # Alternative: pkgs.helix-from-src to be the raw build,
  # and pkgs.helix-wrapped to be the wrapper:
  # helix-from-src = helixFromSrcRaw;
  # helix-wrapped = helixWrappedForHm;
  # Then in Home Manager, use `package = pkgs.helix-wrapped;`
}
