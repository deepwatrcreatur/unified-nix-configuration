# hosts/macminim4/homebrew.nix
{ ... }: {
  imports = [ 
    ../../modules/nix-darwin/homebrew.nix 
  ];

  homebrew.hostSpecific = {
    brews = [
      "opencode"
      "doxx"
    ];
    casks = [
      "claude"
      "discord"
      "gitkraken"
      "karabiner-elements"
      "krita"
      "telegram"
      "visual-studio-code"
      "vlc"
      "zen-browser"
      "zoom"
    ];
  };
}
