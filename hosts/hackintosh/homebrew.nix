# hosts/hackintosh/homebrew.nix
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
      "zoom"
    ];
  };
}
