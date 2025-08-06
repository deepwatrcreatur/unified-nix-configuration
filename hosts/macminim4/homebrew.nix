# hosts/macminim4/homebrew.nix
{ ... }: {
  imports = [ 
    ../../modules/nix-darwin/homebrew.nix 
  ];

  homebrew.hostSpecific = {
    brews = [
      "opencode"
    ];
    casks = [
      "claude"
      "discord"
      "krita"
      "telegram"
      "visual-studio-code"
      "vlc"
      "zen-browser"
      "zoom"
    ];
  };
}
