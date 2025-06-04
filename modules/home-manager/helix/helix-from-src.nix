# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:

let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; };

  tomlFormat = pkgs.formats.toml {};

  # Generate the TOML files as derivations
  configTomlDrv = tomlFormat.generate "config.toml" helixSettingsNix;
  languagesTomlDrv = tomlFormat.generate "languages.toml" helixLanguagesNix;
in
{
  programs.helix.enable = lib.mkForce false;

  home.packages = with pkgs; [
    #helix-from-source-impure
    nil
    nixd
    nixpkgs-fmt
    elixir-ls
  ];

  xdg.configFile."helix/config.toml" = {
    # Read the content of the file produced by the derivation
    text = builtins.readFile configTomlDrv;
  };

  xdg.configFile."helix/languages.toml" = {
    # Read the content of the file produced by the derivation
    text = builtins.readFile languagesTomlDrv;
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
