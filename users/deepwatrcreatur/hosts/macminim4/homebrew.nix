# modules/homebrew.nix
#
# Contains Homebrew configuration shared across ALL macOS hosts.
{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;

    taps = [
      "romkatv/powerlevel10k"
      "gabe565/tap"
    ];

    # Formulas i.e. CLI tools
    brews = [
      "fish"
      "cmake"
      "powerlevel10k"
    ];

    # Casks (GUI Apps)
    casks = [
      "visual-studio-code"
      "font-fira-code"
    ];
  };
  home.sessionPath = [
    # Add the Homebrew binary path for Apple Silicon.
    "/opt/homebrew/bin"
  ];
}
