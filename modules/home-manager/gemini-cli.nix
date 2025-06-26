# modules/home-manager/gemini-cli.nix
{ config, pkgs, ... }:

{
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

  options.myModules.geminiCli.enable = pkgs.lib.mkOption {
    type = pkgs.lib.types.bool;
    default = true;
    description = "Whether to install the Google Gemini CLI globally.";
  };
}
