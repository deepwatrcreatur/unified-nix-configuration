{ config, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ./sops.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.activation = {
    installGeminiCli = ''
      echo "Attempting to install Google Gemini CLI globally..."
      # Capture stderr and stdout to a temporary log file
      # Also, make sure npm is in the PATH or explicitly path to it.
      # We'll explicitly use the Nix-provided npm
      ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli &> "$HOME/.cache/gemini-cli-install.log"

      if [ $? -eq 0 ]; then
        echo "Google Gemini CLI installation successful."
      else
        echo "Google Gemini CLI installation failed. Check $HOME/.cache/gemini-cli-install.log for details."
        # This will make the activation script fail, which is good for debugging
        # as it should then show up in the journal if not before.
        exit 1
      fi
    '';
  };
}
