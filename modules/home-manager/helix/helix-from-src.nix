# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:
let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; };
  tomlFormat = pkgs.formats.toml {};
  configTomlDrv = tomlFormat.generate "config.toml" helixSettingsNix;
  languagesTomlDrv = tomlFormat.generate "languages.toml" helixLanguagesNix;
in
{
  programs.helix.enable = lib.mkForce false; # Disable standard module

  # ONLY manage config files.
  xdg.configFile."helix/config.toml" = {
    text = builtins.readFile configTomlDrv;
  };
  xdg.configFile."helix/languages.toml" = {
    text = builtins.readFile languagesTomlDrv;
  };

  # NO home.packages for helix-from-source-impure
  # NO home.sessionVariables for EDITOR=hx (we'll set this manually or let system do it)
  # NO home.activation scripts for symlinking
  # NO programs.fish.interactiveShellInit for PATH manipulation for hx
}
