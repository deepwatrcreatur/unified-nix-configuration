{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "gemini-cli";
  version = "0.1.4";
  
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
    sha256 = "sha256-QA65tcuOxxyKORREtUEoggAdf6Ou3/ORGtD4FFEQ/KA=";
  };
  
  nativeBuildInputs = with pkgs; [ nodejs npm ];
  
  buildPhase = ''
    # Install dependencies
    npm install --production --no-package-lock
  '';
  
  installPhase = ''
    mkdir -p $out/lib/node_modules/@google/gemini-cli
    cp -r * $out/lib/node_modules/@google/gemini-cli/
    
    # Create bin directory and symlink
    mkdir -p $out/bin
    
    # Create a wrapper script that should work regardless of the internal structure
    cat > $out/bin/gemini << 'EOF'
#!/usr/bin/env bash
exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/@google/gemini-cli/dist/cli.js "$@"
EOF
    chmod +x $out/bin/gemini
  '';
  
  meta = with pkgs.lib; {
    description = "CLI for Google Gemini API";
    homepage = "https://www.npmjs.com/package/@google/gemini-cli";
    license = licenses.asl20;
    platforms = pkgs.lib.platforms.all;
  };
}
