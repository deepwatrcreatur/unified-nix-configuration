# hosts/macminim4/homebrew.nix
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
    "/opt/homebrew/bin"
  ];
}

