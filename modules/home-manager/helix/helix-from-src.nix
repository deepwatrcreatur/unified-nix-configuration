# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:

let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; };
  tomlFormat = pkgs.formats.toml {};

  configTomlDrv = tomlFormat.generate "config.toml" helixSettingsNix;
  languagesTomlDrv = tomlFormat.generate "languages.toml" helixLanguagesNix;

  helixImpurePkg = pkgs.helix-from-source-impure;
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

  # EDITOR and VISUAL are already set in your fish-shared.nix's shellInit.
  # If you want to ensure 'hx' is used and potentially override other settings,
  # you can keep this, or rely on fish-shared.nix.
  # For consistency, if fish-shared.nix sets them, you might not need them here.
  # However, home.sessionVariables is more general than just Fish.
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  home.activation.createHelixSymlink = lib.hm.dag.entryAfter ["writeBoundary"] ''
    HELIX_SYMLINK_DIR="$HOME/.local/bin"
    HELIX_SYMLINK_NAME="hx"
    HELIX_SYMLINK_PATH="$HELIX_SYMLINK_DIR/$HELIX_SYMLINK_NAME"
    ACTUAL_HX_PATH="${helixImpurePkg}/bin/hx"
    mkdir -p "$HELIX_SYMLINK_DIR"
    ln -sf "$ACTUAL_HX_PATH" "$HELIX_SYMLINK_PATH"
    echo "Activation: Symlink for custom Helix created/updated at $HELIX_SYMLINK_PATH"
  '';

  # Add to Fish's initialization scripts.
  # Home Manager will concatenate these strings with those from fish-shared.nix.
  programs.fish.interactiveShellInit = lib.mkIf (config.programs.fish.enable) ''

    # --- Helix Custom PATH (from helix-from-src.nix) ---
    # Add ~/.local/bin to PATH if it exists and isn't already there
    # This ensures the symlink created by home.activation is found.
    if test -d "$HOME/.local/bin"; then
      if not string match -q -- "*$HOME/.local/bin*" $PATH; # Check if already in PATH
        set -gx PATH "$HOME/.local/bin" $PATH;
      end;
    end;
  '';

  programs.fish.loginShellInit = lib.mkIf (config.programs.fish.enable) ''

    # --- Helix Custom PATH (from helix-from-src.nix) ---
    # Add ~/.local/bin to PATH if it exists and isn't already there
    if test -d "$HOME/.local/bin"; then
      if not string match -q -- "*$HOME/.local/bin*" $PATH; # Check if already in PATH
        set -gx PATH "$HOME/.local/bin" $PATH;
      end;
    end;
  '';
}
