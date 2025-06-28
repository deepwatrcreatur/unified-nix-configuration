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
    # Install via npm using home activation
    home.activation.installGeminiCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -z "$DRY_RUN_CMD" ]]; then
        if ! command -v gemini &> /dev/null; then
          echo "Installing @google/gemini-cli..."
          export PATH="${pkgs.nodejs}/bin:$PATH"
          ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli
        fi
      fi
    '';
    
    # Add npm global bin to PATH
    home.sessionPath = [ "$HOME/.npm-global/bin" ];
    
    # Set up npm to use global directory
    home.sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };
    
    # Set up sops secret for Gemini CLI credentials
    sops.secrets."oatuh_creds" = {
      sopsFile = ../../secrets/oauth_creds.json.enc;
      path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
      mode = "0600";
    };
    
    # Ensure .gemini directory exists
    home.file.".gemini/.keep".text = "";
  };
}
