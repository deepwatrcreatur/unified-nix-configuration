# modules/home-manager/gemini-cli.nix
{ config, pkgs, lib, ... }:
{
  options.myModules.geminiCli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Google Gemini CLI globally.";
    };
    
    useNixPackage = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use a Nix package instead of npm install (if available).";
    };
  };

  config = lib.mkIf config.myModules.geminiCli.enable {
    # Option 1: Try to use a Nix package if available and requested
    home.packages = lib.optionals config.myModules.geminiCli.useNixPackage 
      (lib.optionals (pkgs ? nodePackages && pkgs.nodePackages ? "@google/gemini-cli") 
        [ pkgs.nodePackages."@google/gemini-cli" ]);

    # Option 2: Install via npm (default approach)
    home.activation = lib.mkIf (!config.myModules.geminiCli.useNixPackage) {
      installGeminiCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
        echo "Attempting to install Google Gemini CLI globally..."
        
        # Ensure directories exist
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
        
        # Set npm configuration explicitly for this installation
        export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
        export NPM_CONFIG_CACHE="${config.home.homeDirectory}/.npm-cache"
        
        # Use npm with explicit configuration (don't use DRY_RUN_CMD for npm install)
        if ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli --prefix="${config.home.homeDirectory}/.npm-global" &> "${config.home.homeDirectory}/.cache/gemini-cli-install.log"; then
          echo "Google Gemini CLI installation successful."
          # Make the binary executable
          chmod +x "${config.home.homeDirectory}/.npm-global/bin/gemini" 2>/dev/null || true
        else
          echo "Google Gemini CLI installation failed. Check ${config.home.homeDirectory}/.cache/gemini-cli-install.log for details."
          # Don't exit 1 in activation scripts as it can break home-manager
          echo "Continuing with other activations..."
        fi
      '';
    };
  };
}
