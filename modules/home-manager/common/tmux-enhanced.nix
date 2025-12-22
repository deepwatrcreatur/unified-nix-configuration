# modules/home-manager/common/tmux-enhanced.nix
# Inspired by https://github.com/omerxx/dotfiles/tree/master/tmux
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
      default = true;
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

    sessionxPath = mkOption {
      type = types.str;
      default = "~/projects";
      description = "Path for sessionx to search for projects";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional tmux configuration";
    };

    extraPlugins = mkOption {
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
        # Environment variables for enhanced color support
        set-environment -g COLORTERM "truecolor"
        set-environment -g TERM "${cfg.terminal}"
        
        # Basic settings from your tmux.conf with enhanced colors
        set-option -g default-terminal '${cfg.terminal}'
        set-option -g terminal-overrides ',xterm-256color:RGB'
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        setw -g mode-keys vi
        
        # Enhanced pane borders with vibrant colors
        set -g pane-active-border-style 'fg=#89b4fa,bg=#1e1e2e'
        set -g pane-border-style 'fg=#45475a,bg=#1e1e2e'
        
        # Enhanced status bar colors
        set -g status-style 'bg=#1e1e2e,fg=#cdd6f4'
        set -g status-left-style 'bg=#313244,fg=#cdd6f4'
        set -g status-right-style 'bg=#313244,fg=#cdd6f4'
        
        # Window styling with rounded corners effect
        set -g window-status-current-style 'fg=#89b4fa,bg=#313244'
        set -g window-status-style 'fg=#9399a2,bg=#1e1e2e'
        set -g window-status-activity-style 'fg=#f38ba8,bg=#1e1e2e'
        set -g window-status-bell-style 'fg=#f9e2af,bg=#1e1e2e'

        # Plugin configuration
        set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
        set -g @fzf-url-history-limit '2000'

        # Catppuccin theme configuration (omerxx style with enhanced colors)
        ${lib.optionalString cfg.enableCatppuccin ''
        # Enhanced window styling with vibrant colors
        set -g @catppuccin_window_left_separator ""
        set -g @catppuccin_window_right_separator " "
        set -g @catppuccin_window_middle_separator " █"
        set -g @catppuccin_window_number_position "right"
        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_default_text "#W"
        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
        set -g @catppuccin_status_modules_right "directory"
        set -g @catppuccin_status_modules_left "session"
        set -g @catppuccin_status_left_separator  " "
        set -g @catppuccin_status_right_separator " "
        set -g @catppuccin_status_right_separator_inverse "no"
        set -g @catppuccin_status_fill "icon"
        set -g @catppuccin_status_connect_separator "no"
        set -g @catppuccin_directory_text "#{b:pane_current_path}"
        
        # Enhanced color scheme for better visibility
        set -g @catppuccin_window_status_style "bg=default"
        set -g @catppuccin_window_current_status_style "bg=default"
        set -g @catppuccin_window_activity_style "bg=default"
        set -g @catppuccin_window_bell_style "bg=default"
        set -g @catppuccin_window_border_style "bg=default"
        set -g @catppuccin_window_border_status_style "bg=default"
        set -g @catppuccin_window_border_current_status_style "bg=default"
        set -g @catppuccin_window_border_activity_style "bg=default"
        set -g @catppuccin_window_border_bell_style "bg=default"
        ''}

        # Floax configuration (floating window manager)
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-border-color 'magenta'
        set -g @floax-text-color 'blue'
        set -g @floax-bind 'p'
        set -g @floax-change-path 'true'

        # Sessionx configuration (fuzzy session manager)
        set -g @sessionx-bind-zo-new-window 'ctrl-y'
        set -g @sessionx-auto-accept 'off'
        set -g @sessionx-bind 'o'
        set -g @sessionx-x-path '${cfg.sessionxPath}'
        set -g @sessionx-window-height '85%'
        set -g @sessionx-window-width '75%'
        set -g @sessionx-zoxide-mode 'on'
        set -g @sessionx-custom-paths-subdirectories 'false'
        set -g @sessionx-filter-current 'false'
        set -g @sessionx-preview-location 'right'
        set -g @sessionx-preview-ratio '55%'

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
        sensible        # Sensible defaults
        yank            # Copy to system clipboard
        resurrect       # Save/restore sessions
        continuum       # Auto-save sessions
        tmux-thumbs     # Quick copy visible text with hints
        tmux-fzf        # Fzf integration for tmux commands
        fzf-tmux-url    # Open URLs from tmux with fzf
        tmux-sessionx   # Fuzzy session manager
        tmux-floax      # Floating pane manager
      ]
      ++ lib.optional cfg.enableCatppuccin catppuccin
      ++ cfg.extraPlugins;
    };

    # Install dependencies for plugins
    home.packages = with pkgs; [
      ncurses  # Better terminfo support
      fzf      # Required by sessionx, fzf-tmux-url, tmux-fzf
      bat      # Required by sessionx for preview
      zoxide   # Optional but recommended for sessionx
      
      # Enhanced terminal color support
      terminfo-ncurses
      terminfo-terminfo
      terminfo-xterm-256color
    ];
  };
}