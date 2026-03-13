# modules/home-manager/common/dmux.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.dmux;

  # Derivation for the dmux package (Node.js project, manually built)
  dmux-pkg = pkgs.stdenv.mkDerivation rec {
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

      # The package.json has "bin": { "dmux": "./dmux" }
      # The 'dmux' file is likely a shell script that executes the dist/index.js
      cp ./dmux $out/bin/dmux
      # Ensure the dist/ directory is also copied or linked if necessary
      cp -r ./dist $out/lib/${pname}
      chmod +x $out/bin/dmux # Ensure it's executable
    '';

    meta = {
      description = "A development agent multiplexer for git";
      homepage = "https://github.com/standardagents/dmux";
      license = pkgs.lib.licenses.mit; # From package.json
    };
  };

in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ dmux-pkg ];
  };
}
