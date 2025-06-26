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
    # Give your activation script a descriptive name (e.g., 'installGeminiCli')
    installGeminiCli = ''
      echo "Installing Google Gemini CLI globally..."
      ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli
      echo "Google Gemini CLI installed."
    '';
  };
}
