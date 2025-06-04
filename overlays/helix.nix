# overlays/helix.nix
self: super:
let
  versionUtils = import ../flake-modules/version-utils.nix { lib = super.lib; };
in
{
  # This is the direct, impure build
  helix-from-source-impure = super.rustPlatform.buildRustPackage rec {
    pname = "helix-from-source-impure"; # Clear pname
    # ... (rest of your src, version, cargoLock, nativeBuildInputs, __impure, GIT_SSL_CAINFO, meta) ...
    # Ensure __impure = true; and GIT_SSL_CAINFO are here.
    src = super.fetchFromGitHub {
      owner = "helix-editor";
      repo = "helix";
      rev = "1ea9050a5e12a1bc3eeb4b81022f427688c5ffa9";
      sha256 = "KWpXXXciUDJp2DitQWT8MNzhECBuHA2SRPz51t0bZG0="; # Your correct SHA256
      fetchSubmodules = true;
    };
    version = versionUtils.generateVersionFromGitSource src;
    cargoLock = { lockFile = src + "/Cargo.lock"; };
    nativeBuildInputs = with super; [ pkg-config git cacert ];
    buildInputs = with super; [] ++ super.lib.optionals stdenv.isDarwin [ libiconv darwin.apple_sdk.frameworks.SystemConfiguration ];
    __impure = true;
    GIT_SSL_CAINFO = "${super.cacert}/etc/ssl/certs/ca-bundle.crt";
    meta = with super.lib; { /* ... */ };
  };
}
