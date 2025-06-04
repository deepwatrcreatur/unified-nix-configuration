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

  # --- Corrected Symlink Creation ---
  # Create a symlink at ~/.local/bin/hx
  home.file.".local/bin/hx" = {
    # The 'target' attribute specifies that this is a symlink
    # and its value is the path the symlink should point to.
    target = "${pkgs.helix-from-source-impure}/bin/hx";
    # Optional: force = true; # to overwrite if something else exists there, use with caution.
  };

  # Ensure ~/.local/bin is in PATH for Fish (and other shells if used)
  # This merges with any existing interactiveShellInit.
  programs.fish.interactiveShellInit = lib.mkMerge [
    (lib.mkIf (config.programs.fish.enable) ''
      # Add ~/.local/bin to PATH if it exists and isn't already there
      if test -d "$HOME/.local/bin"
        if not string match -q -- "*$HOME/.local/bin*" $PATH # Simple check
          set -gx PATH "$HOME/.local/bin" $PATH
        end
      end
    '')
    config.programs.fish.interactiveShellInit
  ];

  programs.fish.loginShellInit = lib.mkMerge [
    (lib.mkIf (config.programs.fish.enable) ''
      if test -d "$HOME/.local/bin"
        if not string match -q -- "*$HOME/.local/bin*" $PATH
          set -gx PATH "$HOME/.local/bin" $PATH
        end
      end
    '')
    config.programs.fish.loginShellInit
  ];
}
