{ config, pkgs, lib, inputs, ... }:

{
  programs.helix = {
    enable = true;
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
      nodePackages.prettier
      gopls
      go
    ];
    settings = import ./settings.nix;
    languages = import ./languages.nix { inherit pkgs; };
  };
}
