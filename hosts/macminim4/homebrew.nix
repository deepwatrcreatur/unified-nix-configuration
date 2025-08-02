# hosts/macminim4/homebrew.nix
{ nix-homebrew, homebrew-core, homebrew-cask, ... }: {
  imports = [ 
    (import ../../modules/nix-darwin/homebrew.nix {
      inherit nix-homebrew homebrew-core homebrew-cask;
    })
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
