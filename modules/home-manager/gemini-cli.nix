# modules/home-manager/gemini-cli.nix
{ config, pkgs, lib, ... }:

{
  options.myModules.geminiCli.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to install the Google Gemini CLI globally.";
  };

  config = lib.mkIf config.myModules.geminiCli.enable {
    # It's good practice to ensure npm is enabled if geminiCli is enabled,
    # or at least clearly state the dependency.
    # The 'myModules.npm.enable = true;' in your main config will handle this.

    home.activation = {
      installGeminiCli = ''
        echo "Attempting to install Google Gemini CLI globally..."
        # Use the Nix-provided npm, which will now respect the prefix set by programs.npm
        ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli &> "$HOME/.cache/gemini-cli-install.log"

        if [ $? -eq 0 ]; then
          echo "Google Gemini CLI installation successful."
        else
          echo "Google Gemini CLI installation failed. Check $HOME/.cache/gemini-cli-install.log for details."
          exit 1
        fi
      '';
    };
  };
}
