# modules/home-manager/common/tmux-enhanced.nix
# Inspired by https://github.com/omerxx/dotfiles/tree/master/tmux
# Updated for catppuccin/tmux v2.x
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.tmux-enhanced;
  
  # Catppuccin plugin path for manual loading
  catppuccinPlugin = pkgs.tmuxPlugins.catppuccin;
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
      default = "tmux-256color";
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

    catppuccinFlavor = mkOption {
      type = types.enum [ "latte" "frappe" "macchiato" "mocha" ];
      default = "mocha";
      description = "Catppuccin flavor to use";
    };

    windowStyle = mkOption {
      type = types.enum [ "rounded" "basic" "slanted" "custom" ];
      default = "rounded";
      description = "Window status style (rounded gives pill-shaped tabs)";
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
      
      # Note: We DON'T include catppuccin in plugins list because we need to
      # control when it loads (after config options are set)
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
      ] ++ cfg.extraPlugins;
      
      # Configuration - catppuccin options MUST be set before plugin loads
      extraConfig = ''
        # Basic terminal settings
        set-option -g default-terminal '${cfg.terminal}'
        set-option -g terminal-overrides ',xterm-256color:RGB'
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        setw -g mode-keys vi
        set -g pane-active-border-style 'fg=magenta,bg=default'
        set -g pane-border-style 'fg=brightblack,bg=default'
        set -g mouse on

        # Plugin configuration (fzf-url)
        set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
        set -g @fzf-url-history-limit '2000'

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

        ${lib.optionalString cfg.enableCatppuccin ''
        # ============================================= #
        # Catppuccin v2.x Configuration                 #
        # MUST be set BEFORE loading the plugin         #
        # ============================================= #
        
        # Set the flavor
        set -g @catppuccin_flavor '${cfg.catppuccinFlavor}'
        
        # Window status style - "rounded" gives the pill-shaped tabs like omerxx
        set -g @catppuccin_window_status_style '${cfg.windowStyle}'
        
        # Window settings
        set -g @catppuccin_window_number_position 'right'
        set -g @catppuccin_window_text ' #W'
        set -g @catppuccin_window_current_text ' #W#{?window_zoomed_flag, 󰊓,}'
        
        # Pane settings
        set -g @catppuccin_pane_status_enabled 'no'
        set -g @catppuccin_pane_border_status 'off'
        
        # Now load the catppuccin plugin
        run-shell ${catppuccinPlugin}/share/tmux-plugins/catppuccin/catppuccin.tmux
        
        # ============================================= #
        # Status line configuration (AFTER plugin load) #
        # ============================================= #
        
        # Status line length
        set -g status-left-length 100
        set -g status-right-length 100
        
        # Status left - session name with icon
        set -g status-left '#{E:@catppuccin_status_session}'
        
        # Status right - directory and other modules
        set -g status-right '#{E:@catppuccin_status_directory}'
        ''}

        # Custom keybindings
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
    };

    # Install dependencies for plugins
    home.packages = with pkgs; [
      ncurses  # Better terminfo support
      fzf      # Required by sessionx, fzf-tmux-url, tmux-fzf
      bat      # Required by sessionx for preview
      zoxide   # Optional but recommended for sessionx
    ];
  };
}