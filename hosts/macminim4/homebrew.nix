# hosts/macminim4/homebrew.nix
{ ... }:
{
  imports = [
    ../../modules/nix-darwin/homebrew.nix
  ];

  homebrew.hostSpecific = {
    brews = [
      "opencode"
      "doxx"
    ];
    casks = [
      "discord"
      "gitkraken"
      "karabiner-elements"
      "krita"
      "rustdesk"
      "telegram"
      "visual-studio-code"
      "vlc"
      #"zen-browser"  # Temporarily commented out due to installation issues
      "zoom"
    ];
  };
}
