# unified-nix-configuration/pkgs/dmux/default.nix
{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "dmux";
  version = "5.6.1"; # From package.json of standardagents/dmux

  src = pkgs.fetchFromGitHub {
    owner = "standardagents";
    repo = "dmux";
    rev = "v${version}"; # Using version tag for stability
    # Nix will report the correct hash if this is set to "".
    sha256 = "sha256-zdR3KQjh6MSBaut61L7BxIAM7yNEiwH74+YbZ/82I58="; # Corrected sha256 for v5.6.1
  };

  nativeBuildInputs = [
    pkgs.pnpm # For installing dependencies
    pkgs.nodejs # For running the Node.js project
    pkgs.cacert # For SSL certificate validation
    pkgs.gnused # For sed command in installPhase
  ];

  buildPhase = ''
    export PNPM_HOME="$TMPDIR/pnpm-home"
    export PNPM_CACHE_DIR="$TMPDIR/pnpm-cache"
    mkdir -p "$PNPM_HOME" "$PNPM_CACHE_DIR"

    # Install dependencies
    pnpm install --shamefully-hoist --no-frozen-lockfile

    # Run the build script defined in package.json
    pnpm run build
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/${pname} # Ensure the target directory for dist/ exists

    # Copy the main JavaScript source, its dependencies, and workspace packages
    cp -r ./dist $out/lib/${pname}
    cp -r ./node_modules $out/lib/${pname}/node_modules
    # Copy workspace packages that are symlinked from node_modules
    cp -r ./frontend $out/lib/${pname}/frontend
    cp -r ./docs $out/lib/${pname}/docs
    # Copy package.json so AutoUpdater can find it
    cp ./package.json $out/lib/${pname}/package.json

    # The package.json has "bin": { "dmux": "./dmux" }
    # The 'dmux' file is likely a shell script that executes the dist/index.js
    # We need to patch this script to point to the correct installed location.
    sed -i "s|\.\/dist\/index\.js|$out/lib/${pname}/dist/index.js|" ./dmux # Assume relative path
    sed -i "s|\.\.\/dist\/index\.js|$out/lib/${pname}/dist/index.js|" ./dmux # Assume another relative path

    cp ./dmux $out/bin/dmux
    chmod +x $out/bin/dmux # Ensure it's executable
  '';

  meta = {
    description = "A development agent multiplexer for git";
    homepage = "https://github.com/standardagents/dmux";
    license = pkgs.lib.licenses.mit; # From package.json
  };
}
