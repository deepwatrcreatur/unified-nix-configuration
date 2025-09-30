# Overlay for Grok CLI installation
# This overlay builds the @vibe-kit/grok-cli npm package from source
final: prev: {
  grok-cli = final.buildNpmPackage {
    pname = "grok-cli";
    version = "0.0.30";
    
    src = final.fetchFromGitHub {
      owner = "superagent-ai";
      repo = "grok-cli";
      rev = "399d1dccb7aba142bfc44836279aebe812bb2e06";
      sha256 = "sha256-k4CatTS4vul982omwxrD43lzm6097QIJ3V/qRyb6/88=";
    };
    
    npmDepsHash = "sha256-Yl51fCnI3soQ4sGBg4dr+kVak8zYEkMTgyUKDaRK6N0=";

    nativeBuildInputs = with final; [
      python3
    ] ++ (if stdenv.isDarwin then [
      stdenv.cc.cc.lib
      Security
    ] else []);
    
    
    
    meta = with final.lib; {
      description = "An open-source AI agent that brings the power of Grok directly into your terminal";
      homepage = "https://github.com/superagent-ai/grok-cli";
      license = licenses.mit;
      maintainers = [];
    };
  };
}