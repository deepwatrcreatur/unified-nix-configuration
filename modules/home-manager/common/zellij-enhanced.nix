# modules/home-manager/common/zellij-enhanced.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.zellij-enhanced;

  # Sugarplum theme colors (from tmux config)
  sugarplumColors = {
    # Background colors (darker than catppuccin mocha for better contrast)
    background = "#1e1e2e";  # Deep dark background
    surface0 = "#282828";  # Panel backgrounds
    surface1 = "#313244";  # Hover states
    surface2 = "#45475a";  # Borders and dividers
    # Text colors
    text = "#cdd6f4";  # Primary text
    subtext0 = "#a6adc8";  # Secondary text
    # Accent colors (matching sugarplum palette)
    primary = "#ff7eb6";  # Sugarplum pink/coral
    secondary = "#89b4fa";  # Sugarplum blue
    accent = "#94e2d5";  # Sugarplum teal/green
    # UI element colors
    border = "#6272a4";  # Subtle borders
    cursor = "#ff7eb6";  # Match primary
  };

in {
  options.programs.zellij-enhanced = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable enhanced zellij theme with sugarplum palette";
    };
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      
      # Generate theme configuration via extraConfig
      extraConfig = ''
        # Sugarplum theme colors
        fg = "${sugarplumColors.text}"
        bg = "${sugarplumColors.background}"
        black = "${sugarplumColors.background}"
        white = "${sugarplumColors.text}"
        red = "${sugarplumColors.primary}"
        green = "${sugarplumColors.accent}"
        yellow = "${sugarplumColors.primary}"
        blue = "${sugarplumColors.secondary}"
        magenta = "${sugarplumColors.primary}"
        cyan = "${sugarplumColors.accent}"
        
        # UI elements with rounded styling
        ui.tab_bar.bg = "${sugarplumColors.surface0}"
        ui.tab_bar.fg = "${sugarplumColors.text}"
        ui.tab_bar.active_tab.bg = "${sugarplumColors.primary}"
        ui.tab_bar.active_tab.fg = "${sugarplumColors.background}"
        ui.tab_bar.inactive_tab.bg = "${sugarplumColors.surface2}"
        ui.tab_bar.inactive_tab.fg = "${sugarplumColors.subtext0}"
        ui.pane_frames.rounded_corners = true
        ui.pane.bg = "${sugarplumColors.surface0}"
        ui.pane.fg = "${sugarplumColors.text}"
        ui.pane.border_inactive.fg = "${sugarplumColors.border}"
        ui.pane.border_inactive.bg = "${sugarplumColors.background}"
        ui.pane.border_active.fg = "${sugarplumColors.primary}"
        ui.pane.border_active.bg = "${sugarplumColors.background}"
        
        # Mouse mode disabled for better terminal selection
        mouse_mode false
      '';
    };
    
    # Install zellij and xclip for copy/paste functionality
    home.packages = with pkgs; [
      zellij
      xclip
    ];
  };
}
