{ pkgs, ... }:
let
  gemini-cli = pkgs.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "latest"; # or specify exact version
    
    src = pkgs.fetchFromNpm {
      name = "@google/gemini-cli";
      version = version;
    };
    
    npmDepsHash = ""; # You'll need to fill this after first build attempt
    
    dontNpmBuild = true;
  };
in
{
  home.packages = [
  	gemini-cli
  ];
}
