# modules/cli/gemini-cli.nix
{ config, pkgs, ... }: # This still takes these args, which are useful for options

{
  # This option block is fine here
  options.myModules.geminiCli.enable = pkgs.lib.mkOption {
    type = pkgs.lib.types.bool;
    default = false;
    description = "Whether to install the Google Gemini CLI globally.";
  };

  # Use lib.mkIf to conditionally include the configuration when enabled
  config = pkgs.lib.mkIf config.myModules.geminiCli.enable {
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
