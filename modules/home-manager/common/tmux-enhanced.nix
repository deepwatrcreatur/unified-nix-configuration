# modules/home-manager/common/tmux-enhanced.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.tmux-enhanced;
in
{
  options.programs.tmux-enhanced = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable enhanced tmux configuration with catppuccin theming and plugins";
    };

    terminal = mkOption {
      type = types.str;
      default = "screen-256color";
      description = "Terminal type to use";
    };

    prefix = mkOption {
      type = types.str;
      default = "C-a";
      description = "Tmux prefix key";
    };

    enableCatppuccin = mkOption {
      type = types.bool;
      default = true;
      description = "Enable catppuccin theme";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional tmux configuration";
    };

    plugins = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional tmux plugins to install";
    };
  };

  config = mkIf cfg.enable {
      programs.tmux = {
      enable = true;
      prefix = cfg.prefix;
      historyLimit = 1000000;
      escapeTime = 0;
      baseIndex = 1;
      keyMode = "vi";
      
      # Custom configuration combining your existing setup with new theming
      extraConfig = ''
        # Basic settings from your tmux.conf
        set-option -g default-terminal '${cfg.terminal}'
        set-option -g terminal-overrides ',xterm-256color:RGB'
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        setw -g mode-keys vi
        set -g pane-active-border-style 'fg=magenta,bg=default'
        set -g pane-border-style 'fg=brightblack,bg=default'

        # Plugin configuration
        set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
        set -g @fzf-url-history-limit '2000'

        # Catppuccin theme configuration
        ${lib.optionalString cfg.enableCatppuccin ''
        set -g @catppuccin_window_left_separator " "
        set -g @catppuccin_window_right_separator " "
        set -g @catppuccin_window_middle_separator " █"
        set -g @catppuccin_window_number_position "right"
        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_default_text "#W"
        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,( ),}"
        set -g @catppuccin_status_modules_right "directory"
        set -g @catppuccin_status_modules_left "session"
        set -g @catppuccin_status_left_separator  "  "
        set -g @catppuccin_status_right_separator "  "
        set -g @catppuccin_status_right_separator_inverse "no"
        set -g @catppuccin_status_fill "icon"
        set -g @catppuccin_status_connect_separator "no"
        set -g @catppuccin_directory_text "#{b:pane_current_path}"
        ''}

        # Floax configuration (floating window manager)
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-border-color 'magenta'
        set -g @floax-text-color 'blue'
        set -g @floax-bind 'p'
        set -g @floax-change-path 'true'

        # Sessionx configuration
        set -g @sessionx-bind-zo-new-window 'ctrl-y'
        set -g @sessionx-auto-accept 'off'
        set -g @sessionx-bind 'o'
        set -g @sessionx-x-path '~/dotfiles'
        set -g @sessionx-window-height '85%'
        set -g @sessionx-window-width '75%'
        set -g @sessionx-zoxide-mode 'on'
        set -g @sessionx-custom-paths-subdirectories 'false'
        set -g @sessionx-filter-current 'false'

        # Continuum and resurrect settings
        set -g @continuum-restore 'on'
        set -g @resurrect-strategy-nvim 'session'

        # Custom keybindings from tmux.reset.conf
        bind ^X lock-server
        bind ^C new-window -c "$HOME"
        bind ^D detach
        bind * list-clients
        bind H previous-window
        bind L next-window
        bind r command-prompt "rename-window %%"
        bind R source-file ~/.config/tmux/tmux.conf
        bind ^A last-window
        bind ^W list-windows
        bind w list-windows
        bind z resize-pane -Z
        bind ^L refresh-client
        bind l refresh-client
        bind | split-window
        bind s split-window -v -c "#{pane_current_path}"
        bind v split-window -h -c "#{pane_current_path}"
        bind '"' choose-window
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
        bind -r -T prefix , resize-pane -L 20
        bind -r -T prefix . resize-pane -R 20
        bind -r -T prefix - resize-pane -D 7
        bind -r -T prefix = resize-pane -U 7
        bind : command-prompt
        bind * setw synchronize-panes
        bind P set pane-border-status
        bind c kill-pane
        bind x swap-pane -D
        bind S choose-session
        bind K send-keys "clear"\; send-keys "Enter"
        bind-key -T copy-mode-vi v send-keys -X begin-selection

        ${cfg.extraConfig}
      '';

      # Enhanced plugin list
      plugins = with pkgs.tmuxPlugins; [
        tpm
        sensible
        yank
        resurrect
        continuum
        thumbs
        fzf
        tmux-fzf-url
        (mkIf cfg.enableCatppuccin catppuccin)
        sessionx
        floax
      ] ++ cfg.plugins;
    };

    # Install tmux with better terminfo support
    home.packages = with pkgs; [
      tmux
      ncurses  # For better terminfo support
    ];
  };
}