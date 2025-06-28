# modules/home-manager/gemini-cli.nix
{ config, pkgs, lib, ... }:

{
  options.myModules.geminiCli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Google Gemini CLI.";
    };
  };

  config = lib.mkIf config.myModules.geminiCli.enable {
    # Install via npm using home activation (relies on npm.nix for PATH setup)
    home.activation.installGeminiCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -z "$DRY_RUN_CMD" ]]; then
        if ! command -v gemini &> /dev/null; then
          echo "Installing @google/gemini-cli..."
          # Set PATH explicitly to include nodejs for npm's postinstall scripts
          PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli
        fi
      fi
    '';

    # Ensure .gemini directory exists (sops will place oauth_creds.json here)
    home.file.".gemini/.keep".text = "";
  };
}
