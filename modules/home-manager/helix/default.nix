{ config, pkgs, lib, inputs, ... }:

{
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.system}.helix;
    defaultEditor = true;
    extraPackages = with pkgs; [
      nil
      nixd
      nixpkgs-fmt
      elixir-ls
      yaml-language-server
      pyright
      black
      typescript-language-server
      prettier
      gopls
      go
    ];
    settings = import ./settings.nix;
    languages = import ./languages.nix { inherit pkgs; };
  };
}
