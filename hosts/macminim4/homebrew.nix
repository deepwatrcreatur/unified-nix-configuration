# hosts/macminim4/homebrew.nix
{ ... }: {
  imports = [ 
    import ../../modules/nix-darwin/homebrew.nix 
  ];

  homebrew.hostSpecific = {
    taps = [
      "sst/tap"
    ];
    brews = [
      "opencode"
    ];
    casks = [
      "visual-studio-code"
      "zen-browser"
    ];
  };
}
