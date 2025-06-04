
# modules/home-manager/helix/helix-from-src.nix
{ config, pkgs, lib, ... }:

let
  helixSettingsNix = import ./settings.nix;
  helixLanguagesNix = import ./languages.nix { inherit pkgs; };
  tomlFormat = pkgs.formats.toml {};

  configTomlDrv = tomlFormat.generate "config.toml" helixSettingsNix;
  languagesTomlDrv = tomlFormat.generate "languages.toml" helixLanguagesNix;

  # Get the path to your impurely built Helix.
  # pkgs.helix-from-source-impure will resolve to the store path of your custom build.
  customHelixPath = "${pkgs.helix-from-source-impure}/bin";
in
{
  # Force disable the standard programs.helix module.
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

  # Set as default editor.
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # Manually add custom Helix to the PATH.
  # needs to be done for each shell

  # For Fish shell:
  programs.fish.interactiveShellInit = ''
    # Add custom Helix to PATH if it's not already there
    if not string match -q -- "*/${customHelixPath}/*" $PATH
      set -gx PATH "${customHelixPath}" $PATH
    end
  '';
  # in non-interactive fish sessions (e.g., for scripts):
  programs.fish.loginShellInit = ''
    if not string match -q -- "*/${customHelixPath}/*" $PATH
      set -gx PATH "${customHelixPath}" $PATH
    end
  '';


  programs.bash.initExtra = ''
    export PATH="${customHelixPath}:$PATH"
  '';
  programs.zsh.initExtra = ''
    export PATH="${customHelixPath}:$PATH"
  '';

  programs.nushell.extraConfig = ''
    let-env PATH = ($env.PATH | prepend '${customHelixPath}')
  '';
}
