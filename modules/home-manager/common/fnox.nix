{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Configure fnox environment variables
  home.sessionVariables = {
    # Point fnox to the sops age key
    FNOX_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # NOTE: Do not manage fnox config contents via Nix.
  # Users store/update secrets via `fnox set -g ...`, which writes to:
  #   ~/.config/fnox/config.toml
  # Make `fnox` discover it everywhere under $HOME by symlinking:
  #   ~/fnox.toml -> ~/.config/fnox/config.toml
  home.file."fnox.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/fnox/config.toml";

  # Shell integration
  # - Activate fnox hooks (per-shell)
  # - Export ALL secrets into the interactive environment
  #   (user requested "export everything")
  programs.bash.initExtra = ''
    if command -v fnox >/dev/null 2>&1 && [ -f "$HOME/fnox.toml" ]; then
      eval "$(fnox activate bash -c \"$HOME/fnox.toml\")"
      set -a
      # fnox export emits KEY=value lines
      source <(fnox export -c "$HOME/fnox.toml" --format env 2>/dev/null)
      set +a
    fi
  '';

  programs.zsh.initContent = ''
    if command -v fnox >/dev/null 2>&1 && [ -f "$HOME/fnox.toml" ]; then
      eval "$(fnox activate zsh -c \"$HOME/fnox.toml\")"
      set -a
      source <(fnox export -c "$HOME/fnox.toml" --format env 2>/dev/null)
      set +a
    fi
  '';

  programs.fish.interactiveShellInit = ''
    if command -v fnox >/dev/null; and test -f "$HOME/fnox.toml"
      fnox activate fish -c "$HOME/fnox.toml" | source

      for line in (fnox export -c "$HOME/fnox.toml" --format env 2>/dev/null)
        set -l kv (string split -m1 "=" -- $line)
        if test (count $kv) -ge 2
          set -gx $kv[1] $kv[2]
        end
      end
    end
  '';

  # Nushell isn't listed in `fnox activate` help; keep it no-op for now.
  programs.nushell.extraConfig = "";
}
