# modules/home-manager/helix-config.nix
{ config, pkgs, lib, ... }: 

{
  programs.helix = {
    enable = true;
    # Use the custom-built package from the overlay
    package = pkgs.helix-from-src;
    defaultEditor = true;
    extraPackages = with pkgs; [ 
      nil
      nixd
      nixpkgs-fmt
      elixir-ls
    ];
    settings = import ./settings.nix; 
    languages = import ./languages.nix { inherit pkgs; };
  };
}
