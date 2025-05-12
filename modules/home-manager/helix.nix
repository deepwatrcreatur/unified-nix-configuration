{ config, pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      nil
      nixd
      nixpkgs-fmt
      elixir-ls
    ];
    settings = import ./helix-config/settings.nix;
    languages = import ./helix-config/languages.nix { inherit pkgs; };
  };
}

