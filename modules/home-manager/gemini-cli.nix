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
        $DRY_RUN_CMD mkdir -p $HOME/.npm-global
        $DRY_RUN_CMD mkdir -p $HOME/.npm-cache
        
        # Set npm configuration explicitly for this installation
        export NPM_CONFIG_PREFIX="$HOME/.npm-global"
        export NPM_CONFIG_CACHE="$HOME/.npm-cache"
        
        # Use npm with explicit configuration
        if $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli --prefix="$HOME/.npm-global" &> "$HOME/.cache/gemini-cli-install.log"; then
          echo "Google Gemini CLI installation successful."
        else
          echo "Google Gemini CLI installation failed. Check $HOME/.cache/gemini-cli-install.log for details."
          # Don't exit 1 in activation scripts as it can break home-manager
          echo "Continuing with other activations..."
        fi
      '';
    };
  };
}
