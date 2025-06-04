# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:

let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; }; 

  # Helper for TOML generation
  tomlFormat = pkgs.formats.toml {}; # Get the TOML format generator

in
{
  #    in case programs.helix.enable = true elsewhere for this user
  programs.helix.enable = lib.mkForce false; # Force disable the standard module

  home.packages = with pkgs; [
    helix-from-source-impure 
    nil
    nixd
    nixpkgs-fmt
    elixir-ls
  ];

  xdg.configFile."helix/config.toml" = {
    # generate "filename" <attrset>
    text = tomlFormat.generate "config.toml" helixSettingsNix;
    # Ensure helixSettingsNix returns an attribute set suitable for TOML.
  };

  xdg.configFile."helix/languages.toml" = {
    text = tomlFormat.generate "languages.toml" helixLanguagesNix;
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
