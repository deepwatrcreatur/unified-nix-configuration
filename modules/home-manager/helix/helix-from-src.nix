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
  programs.helix.enable = lib.mkForce false;

  home.packages = with pkgs; [
    nil
    nixd
    nixpkgs-fmt
    elixir-ls
  ];

  xdg.configFile."helix/config.toml" = {
    text = builtins.readFile configTomlDrv;
  };

  xdg.configFile."helix/languages.toml" = {
    text = builtins.readFile languagesTomlDrv;
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # --- New PATH Management using symlink ---
  # Ensure ~/.local/bin is in PATH 
  home.path = [ "$HOME/.local/bin" ]; 

  # Create a symlink to custom hx binary
  home.symlink.".local/bin/hx" = {
    # target is the path to the hx binary from impure build
    target = "${pkgs.helix-from-source-impure}/bin/hx";
    # creates a symlink at ~/.local/bin/hx pointing to the store path.
    # The derivation that creates this symlink is pure.
  };
}
