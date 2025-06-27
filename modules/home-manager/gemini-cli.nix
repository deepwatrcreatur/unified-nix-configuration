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
        echo "Installing Google Gemini CLI via npm..."
        
        # Ensure directories exist
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global/bin
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global/lib
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
        
        # Only proceed if not in dry-run mode
        if [[ -z "$DRY_RUN_CMD" ]]; then
          # Set npm configuration explicitly for this installation
          export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
          export NPM_CONFIG_CACHE="${config.home.homeDirectory}/.npm-cache"
          
          # Ensure node is in PATH for post-install scripts
          export PATH="${pkgs.nodejs}/bin:$PATH"
          
          # Check if already installed and up to date
          if [[ -x "${config.home.homeDirectory}/.npm-global/bin/gemini" ]]; then
            echo "Gemini CLI is already installed and executable."
          else
            echo "Installing @google/gemini-cli..."
            
            # Use npm with explicit configuration
            if ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli \
                --prefix="${config.home.homeDirectory}/.npm-global" \
                --cache="${config.home.homeDirectory}/.npm-cache" \
                &> "${config.home.homeDirectory}/.cache/gemini-cli-install.log"; then
              
              echo "Google Gemini CLI installation successful."
              
              # Ensure the binary is executable
              if [[ -f "${config.home.homeDirectory}/.npm-global/bin/gemini" ]]; then
                chmod +x "${config.home.homeDirectory}/.npm-global/bin/gemini"
                echo "Made gemini binary executable."
              fi
            else
              echo "Google Gemini CLI installation failed. Check ${config.home.homeDirectory}/.cache/gemini-cli-install.log for details."
              echo "Continuing with other activations..."
            fi
          fi
        else
          echo "Dry run mode - would install @google/gemini-cli"
        fi
      '';
    };
  };
}
