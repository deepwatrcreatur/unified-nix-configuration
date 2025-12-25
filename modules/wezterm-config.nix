# modules/wezterm-config.nix - Your configuration file
{ pkgs, ... }:
{
  imports = [ ./wezterm.nix ];
  programs.wezterm = {
    enable = true;
    font = {
      name = "JetBrains Mono";
      size = 16.0;
    };
    window = {
      opacity = 1.0;
      decorations = "RESIZE";
      adjustSizeWhenChangingFont = false;
    };
    tabs.enable = false;
    scrollbackLines = 5000;
    macos = {
      nativeFullscreen = true;
      windowBackgroundBlur = 30;
    };
    keyBindings = [
      {
        key = "q";
        mods = "CTRL";
        action = "ToggleFullScreen";
      }
      {
        key = "\\\"";
        mods = "CTRL";
        action = "ClearScrollback 'ScrollbackAndViewport'";
      }
    ];
    extraConfig = ''
      -- Sugarplum theme colors (matching Ghostty)
      local sugarplum = {
        foreground = "#db7ddd",
        background = "#111147", 
        cursor_bg = "#53b397",
        cursor_fg = "#53b397",
        cursor_border = "#53b397",
        selection_bg = "#5ca8dc",
        selection_fg = "#d0beee",
        ansi = {
          "#111147", -- black
          "#5ca8dc", -- red  
          "#53b397", -- green
          "#249a84", -- yellow
          "#db7ddd", -- blue
          "#d0beee", -- magenta
          "#f9f3f9", -- cyan
          "#a175d4", -- white
        },
        brights = {
          "#111147", -- bright black
          "#5cb5dc", -- bright red
          "#52deb5", -- bright green
          "#01f5c7", -- bright yellow
          "#fa5dfd", -- bright blue
          "#c6a5fd", -- bright magenta
          "#ffffff", -- bright cyan
          "#b577fd", -- bright white
        }
      }

      -- Apply Sugarplum theme instead of color scheme
      config.colors = sugarplum

      -- Mouse bindings (manual for now)
      config.mouse_bindings = {
        {
          event = { Up = { streak = 1, button = "Left" } },
          mods = "CTRL",
          action = wezterm.action.OpenLinkAtMouseCursor,
        },
      }
    '';
  };
}