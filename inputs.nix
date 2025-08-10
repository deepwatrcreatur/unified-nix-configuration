# inputs.nix
{
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  nix-darwin.url = "github:LnL7/nix-darwin/master";
  nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";

  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  determinate.inputs.nixpkgs.follows = "nixpkgs";

  nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

  homebrew-core = {
    url = "github:homebrew/homebrew-core";
    flake = false;
  };

  homebrew-cask = {
    url = "github:homebrew/homebrew-cask";
    flake = false;
  };

  tap-romkatv-powerlevel10k = {
    url = "github:romkatv/powerlevel10k";
    flake = false;
  };

  tap-gabe565 = {
    url = "github:gabe565/homebrew-tap";
    flake = false;
  };

  tap-sst = {
    url = "github:sst/homebrew-tap";
    flake = false;
  };
}
