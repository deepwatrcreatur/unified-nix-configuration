{ config, pkgs, lib, ... }:

let
  gemini-cli = pkgs.stdenv.mkDerivation rec {
    pname = "gemini-cli";
    version = "0.1.4";
    
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
      sha256 = "sha256-QA65tcuOxxyKORREtUEoggAdf6Ou3/ORGtD4FFEQ/KA=";
    };
    
    nativeBuildInputs = with pkgs; [ nodejs ];
    
    buildPhase = ''
      npm install --production --no-package-lock
    '';
    
    installPhase = ''
      mkdir -p $out/lib/node_modules/@google/gemini-cli
      cp -r * $out/lib/node_modules/@google/gemini-cli/
      
      mkdir -p $out/bin
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
      platforms = platforms.all;
    };
  };
in
{
  options.myModules.geminiCli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Google Gemini CLI.";
    };
  };

  config = lib.mkIf config.myModules.geminiCli.enable {
    # Install the Gemini CLI package
    home.packages = [ gemini-cli ];
    
    # Set up sops secret for Gemini CLI credentials
    sops.secrets."oath_creds" = {
      path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
      mode = "0600";
    };
    
    # Ensure .gemini directory exists
    home.file.".gemini/.keep".text = "";
  };
}
