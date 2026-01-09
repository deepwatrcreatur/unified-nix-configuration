{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zellij-extended;
in {
  options.programs.zellij-extended = {
    enable = mkEnableOption "Zellij configuration with catppuccin theme and Ctrl-Alt keybindings";
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        show_startup_tips = false;
        default_layout = "extended";
        
        themes.catppuccin-mocha = {
          bg = "#585b70";
          fg = "#cdd6f4";
          red = "#f38ba8";
          green = "#a6e3a1";
          blue = "#89b4fa";
          yellow = "#f9e2af";
          magenta = "#cba6f7";
          orange = "#fab387";
          cyan = "#89dceb";
          black = "#181825";
          white = "#cdd6f4";
        };

        keybinds = {
          normal = {
            # Unbind default Ctrl keybindings
            "unbind \"Ctrl t\"" = {};
            "unbind \"Ctrl p\"" = {};
            "unbind \"Ctrl s\"" = {};
            "unbind \"Ctrl n\"" = {};
            "unbind \"Ctrl h\"" = {};
            "unbind \"Ctrl j\"" = {};
            "unbind \"Ctrl k\"" = {};
            "unbind \"Ctrl l\"" = {};
            "unbind \"Ctrl o\"" = {};
            "unbind \"Ctrl q\"" = {};
            "unbind \"Ctrl g\"" = {};
            "unbind \"Ctrl b\"" = {};

            # Tab management (Ctrl-Alt)
            "bind \"Ctrl Alt t\"" = { SwitchToMode = "Tab"; };
            "bind \"Ctrl Alt c\"" = { NewTab = {}; };
            "bind \"Ctrl Alt x\"" = { CloseTab = {}; };
            "bind \"Ctrl Alt [\"" = { GoToPreviousTab = {}; };
            "bind \"Ctrl Alt ]\"" = { GoToNextTab = {}; };
            "bind \"Ctrl Alt 1\"" = { GoToTab = 1; };
            "bind \"Ctrl Alt 2\"" = { GoToTab = 2; };
            "bind \"Ctrl Alt 3\"" = { GoToTab = 3; };
            "bind \"Ctrl Alt 4\"" = { GoToTab = 4; };
            "bind \"Ctrl Alt 5\"" = { GoToTab = 5; };
            "bind \"Ctrl Alt 6\"" = { GoToTab = 6; };
            "bind \"Ctrl Alt 7\"" = { GoToTab = 7; };
            "bind \"Ctrl Alt 8\"" = { GoToTab = 8; };
            "bind \"Ctrl Alt 9\"" = { GoToTab = 9; };
            
            # Pane management (Ctrl-Alt)
            "bind \"Ctrl Alt p\"" = { SwitchToMode = "Pane"; };
            "bind \"Ctrl Alt s\"" = { NewPane = "Down"; };
            "bind \"Ctrl Alt v\"" = { NewPane = "Right"; };
            "bind \"Ctrl Alt h\"" = { MoveFocus = "Left"; };
            "bind \"Ctrl Alt j\"" = { MoveFocus = "Down"; };
            "bind \"Ctrl Alt k\"" = { MoveFocus = "Up"; };
            "bind \"Ctrl Alt l\"" = { MoveFocus = "Right"; };
            
            # Fullscreen
            "bind \"Ctrl Alt f\"" = { ToggleFocusFullscreen = {}; SwitchToMode = "Normal"; };
            "bind \"Ctrl Alt z\"" = { ToggleFocusFullscreen = {}; SwitchToMode = "Normal"; };
            
            # Back to normal mode
            "bind \"Esc\"" = { SwitchToMode = "Normal"; };
            
            # Quit
            "bind \"Ctrl Alt q\"" = { Quit = {}; };
          };
          
          # Pane mode keybindings
          pane = {
            "bind \"h\"" = { MoveFocus = "Left"; };
            "bind \"j\"" = { MoveFocus = "Down"; };
            "bind \"k\"" = { MoveFocus = "Up"; };
            "bind \"l\"" = { MoveFocus = "Right"; };
            "bind \"p\"" = { NewPane = "Left"; };
            "bind \"n\"" = { NewPane = "Down"; };
            "bind \"x\"" = { CloseFocus = {}; };
            "bind \"f\"" = { ToggleFocusFullscreen = {}; SwitchToMode = "Normal"; };
            "bind \"z\"" = { ToggleFocusFullscreen = {}; SwitchToMode = "Normal"; };
            "bind \"Esc\"" = { SwitchToMode = "Normal"; };
          };
          
          # Tab mode keybindings
          tab = {
            "bind \"h\"" = { GoToPreviousTab = {}; };
            "bind \"l\"" = { GoToNextTab = {}; };
            "bind \"1\"" = { GoToTab = 1; };
            "bind \"2\"" = { GoToTab = 2; };
            "bind \"3\"" = { GoToTab = 3; };
            "bind \"4\"" = { GoToTab = 4; };
            "bind \"5\"" = { GoToTab = 5; };
            "bind \"6\"" = { GoToTab = 6; };
            "bind \"7\"" = { GoToTab = 7; };
            "bind \"8\"" = { GoToTab = 8; };
            "bind \"9\"" = { GoToTab = 9; };
            "bind \"c\"" = { NewTab = {}; };
            "bind \"x\"" = { CloseTab = {}; };
            "bind \"r\"" = { SwitchToMode = "RenameTab"; };
            "bind \"s\"" = { SwitchToMode = "Session"; };
            "bind \"Esc\"" = { SwitchToMode = "Normal"; };
          };
          
          # Resize mode keybindings
          resize = {
            "bind \"h\"" = { Resize = "Increase Left"; };
            "bind \"j\"" = { Resize = "Increase Down"; };
            "bind \"k\"" = { Resize = "Increase Up"; };
            "bind \"l\"" = { Resize = "Increase Right"; };
            "bind \"H\"" = { Resize = "Decrease Left"; };
            "bind \"J\"" = { Resize = "Decrease Down"; };
            "bind \"K\"" = { Resize = "Decrease Up"; };
            "bind \"L\"" = { Resize = "Decrease Right"; };
            "bind \"=\"" = { Resize = "Increase"; };
            "bind \"-\"" = { Resize = "Decrease"; };
          };
          
          # Search mode keybindings
          search = {
            "bind \"c\"" = { ScrollDown = {}; };
            "bind \"C\"" = { ScrollUp = {}; };
            "bind \"n\"" = { ScrollDown = {}; };
            "bind \"N\"" = { ScrollUp = {}; };
            "bind \"Esc\"" = { SwitchToMode = "Normal"; };
          };
          
          # Session mode keybindings
          session = {
            "bind \"d\"" = { Detach = {}; };
            "bind \"w\"" = {
              LaunchOrFocusPlugin = "zellij:session-manager";
              SwitchToMode = "Normal";
            };
            "bind \"Esc\"" = { SwitchToMode = "Normal"; };
          };
          
          # Locked mode
          locked = {
            "bind \"Ctrl Alt Space\"" = { SwitchToMode = "Normal"; };
          };
        };
      };
    };

    # Define an extended layout with rounded corners and vivid colors
    xdg.configFile."zellij/layouts/extended.kdl".text = ''
      layout {
          pane size=1 borderless=true {
              plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                  # Standard vivid bar at the top
                  format_left   "#[bg=#89B4FA,fg=#1e1e2e,bold]  {session} #[bg=#1e1e2e,fg=#89B4FA] {tabs}"
                  format_right  "#[fg=#89B4FA,bold]#[bg=#89B4FA,fg=#1e1e2e,bold] 󰃭 {datetime} "
                  format_space  ""

                  border_enabled  "false"

                  tab_normal   "#[fg=#6C7086] {index} {name} "
                  tab_active   "#[bg=#313244,fg=#a6e3a1,bold] #[bg=#a6e3a1,fg=#1e1e2e,bold]{index} {name}#[bg=#1e1e2e,fg=#a6e3a1] "

                  datetime        "{format}"
                  datetime_format "%H:%M"
                  datetime_timezone "Europe/Berlin"
              }
          }
          pane
          pane size=2 borderless=true {
              plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                  # Vivid Guide/Status bar at the bottom with Ctrl+Alt hints
                  format_left   "{mode}"
                  format_center "#[fg=#89B4FA,bold]Ctrl+Alt: [t]ab [p]ane [s]plit [v]ert [h/j/k/l]focus [f]ull [q]uit"
                  format_right  "#[fg=#cba6f7,bold]#[bg=#cba6f7,fg=#1e1e2e,bold]  {command_git_branch} "
                  format_space  ""

                  mode_normal  "#[bg=#89B4FA,fg=#1e1e2e,bold] NORMAL #[bg=#1e1e2e,fg=#89B4FA]"
                  mode_locked  "#[bg=#f38ba8,fg=#1e1e2e,bold] LOCKED #[bg=#1e1e2e,fg=#f38ba8]"
                  mode_resize  "#[bg=#f9e2af,fg=#1e1e2e,bold] RESIZE #[bg=#1e1e2e,fg=#f9e2af]"
                  mode_pane    "#[bg=#cba6f7,fg=#1e1e2e,bold] PANE #[bg=#1e1e2e,fg=#cba6f7]"
                  mode_tab     "#[bg=#a6e3a1,fg=#1e1e2e,bold] TAB #[bg=#1e1e2e,fg=#a6e3a1]"
                  mode_scroll  "#[bg=#fab387,fg=#1e1e2e,bold] SCROLL #[bg=#1e1e2e,fg=#fab387]"
                  mode_session "#[bg=#cba6f7,fg=#1e1e2e,bold] SESSION #[bg=#1e1e2e,fg=#cba6f7]"

                  command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                  command_git_branch_format      "{stdout}"
                  command_git_branch_interval    "10"
                  command_git_branch_rendermode  "static"
              }
          }
      }
    '';
  };
}