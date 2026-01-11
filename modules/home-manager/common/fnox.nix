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
  # Bootstrap a writable fnox config in $HOME.
  # - We only create it if missing/empty so user edits persist.
  # - Keep config in ~/.config/fnox/config.toml and expose it as ~/fnox.toml
  #   so fnox's default upward search finds it from any subdir.
  home.activation.fnoxBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg_dir="$HOME/.config/fnox"
        cfg_file="$cfg_dir/config.toml"

        $DRY_RUN_CMD mkdir -p "$cfg_dir"

        if [ ! -s "$cfg_file" ]; then
          $DRY_RUN_CMD cat > "$cfg_file" <<'EOF'
    [providers]
    age = { type = "age", recipients = [
      "age17mn5lnlh2mgttp950wc7a2nl9kphewa4jj8e0uhlv3svx68a54vqyngcyr",
      "age1awqed0la6x3rr39et8fjruw42mf8v2sqct78mcjzx5d226gcx9nqrjdmjz",
    ] }
    EOF
          $VERBOSE_ECHO "Initialized fnox config at $cfg_file"
        fi
  '';

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
