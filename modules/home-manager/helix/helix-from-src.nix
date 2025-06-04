# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:

let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; };
  tomlFormat = pkgs.formats.toml {};

  configTomlDrv = tomlFormat.generate "config.toml" helixSettingsNix;
  languagesTomlDrv = tomlFormat.generate "languages.toml" helixLanguagesNix;

  # The impure Helix package from your overlay
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

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # --- PATH Management using an Activation Script ---
  home.activation.createHelixSymlink = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # This script runs during 'home-manager switch' after packages are built.
    # Target directory for the symlink
    HELIX_SYMLINK_DIR="$HOME/.local/bin"
    # Name of the symlink
    HELIX_SYMLINK_NAME="hx"
    # Full path to the symlink
    HELIX_SYMLINK_PATH="$HELIX_SYMLINK_DIR/$HELIX_SYMLINK_NAME"

    # Path to the actual hx binary from your impure build.
    # Nix will substitute the store path of helixImpurePkg here.
    ACTUAL_HX_PATH="${helixImpurePkg}/bin/hx"

    # Ensure the target directory exists
    mkdir -p "$HELIX_SYMLINK_DIR"

    # Create or update the symlink
    # Use -f to force overwrite if it exists, -s for symbolic
    ln -sf "$ACTUAL_HX_PATH" "$HELIX_SYMLINK_PATH"

    # Optional: Print a message
    echo "Activation: Symlink for custom Helix created/updated at $HELIX_SYMLINK_PATH"
  '';

  # Ensure ~/.local/bin is in PATH for Fish (and other shells if used)
  programs.fish.interactiveShellInit = lib.mkMerge [
    (lib.mkIf (config.programs.fish.enable) ''
      if test -d "$HOME/.local/bin"; then
        if not string match -q -- "*$HOME/.local/bin*" $PATH;
          set -gx PATH "$HOME/.local/bin" $PATH;
        end;
      end;
    '')
    config.programs.fish.interactiveShellInit
  ];
  programs.fish.loginShellInit = lib.mkMerge [
    (lib.mkIf (config.programs.fish.enable) ''
      if test -d "$HOME/.local/bin"; then
        if not string match -q -- "*$HOME/.local/bin*" $PATH;
          set -gx PATH "$HOME/.local/bin" $PATH;
        end;
      end;
    '')
    config.programs.fish.loginShellInit
  ];
}
