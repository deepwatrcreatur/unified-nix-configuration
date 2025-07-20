# hosts/macminim4/homebrew.nix
#
# Contains Homebrew configuration shared across ALL macOS hosts.
{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true; # Auto-update Homebrew during rebuild
      cleanup = "zap";   # Remove unlisted casks/formulae
    };
    
    taps = [
      "romkatv/powerlevel10k"
      "gabe565/tap"
    ];

    # Formulas i.e. CLI tools
    brews = [
      "fish"
      "cmake"
      "powerlevel10k"
      "bitwarden-cli"
    ];

    # Casks (GUI Apps)
    casks = [
      "visual-studio-code"
      "font-fira-code"
      "rustdesk"
    ];
  };
}
