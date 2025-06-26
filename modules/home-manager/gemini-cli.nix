# modules/cli/gemini-cli.nix
{ config, pkgs, lib, ... }: # Make sure 'lib' is also available as an argument

{
  options.myModules.geminiCli.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to install the Google Gemini CLI globally.";
  };

  # Apply lib.mkIf directly to the 'home' attribute,
  # or to the parts of 'config' that are conditional.
  config = lib.mkIf config.myModules.geminiCli.enable {
    home.packages = with pkgs; [
      nodejs # Ensure Node.js and npm are available
    ];

    home.activation = {
      installGeminiCli = ''
        echo "Installing Google Gemini CLI globally..."
        ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli
        echo "Google Gemini CLI installed."
      '';
    };
  };
}
