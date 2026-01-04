{ config, pkgs, ... }:

{
  # Rofi application launcher configuration
  # Default mode: drun (show available applications)
  # Keybinding: Super+Space via dconf settings in cosmic-settings.nix

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modes = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      window-format = "{w} {c} {t}";
      icon-theme = "Adwaita";
      font = "SF Pro Display 12";
      matching = "glob";
      tokenize = true;
      scroll-method = 0; # Smooth scrolling
      terminal = "${pkgs.ghostty}/bin/ghostty";
    };
  };

  # Improved Rofi theme for COSMIC - modern dark aesthetic with macOS-like styling
  xdg.configFile."rofi/theme.rasi".text = ''
    * {
      /* Colors inspired by macOS Dark Mode */
      bg0:      #0d0d0d;
      bg1:      #1a1a1a;
      bg2:      #2a2a2a;
      fg0:      #e8e8e8;
      fg1:      #ffffff;
      accent:   #0a84ff;
      success:  #34c759;
      error:    #ff3b30;
    }

    * {
      background-color: transparent;
      text-color:       @fg0;
    }

    /* Main window container */
    window {
      transparency:   "real";
      background-color: @bg0;
      border:         2px solid @accent;
      border-radius:  12px;
      width:          600px;
      height:         400px;
      location:       center;
      anchor:         center;
    }

    /* Message area */
    message {
      background-color: @bg1;
      padding:         10px 15px;
      border-bottom:   1px solid @bg2;
    }

    /* Input field */
    inputbar {
      children:       [ prompt, entry ];
      spacing:        10px;
      margin:         15px 20px 10px 20px;
      background-color: transparent;
    }

    prompt {
      text-color:     @accent;
      font:           "SF Pro Display Bold 12";
      padding:        5px 0px;
    }

    entry {
      background-color: @bg2;
      text-color:      @fg0;
      padding:         8px 12px;
      border-radius:   6px;
      placeholder:     "Search applications...";
      placeholder-color: #888888;
    }

    /* List of applications */
    listview {
      background-color: transparent;
      padding:         10px 0px;
      lines:           8;
      columns:         1;
      dynamic:         true;
      fixed-height:    false;
      scrollbar:       false;
    }

    /* Application entry styling */
    element {
      padding:         8px 15px;
      margin:          2px 10px;
      background-color: transparent;
      text-color:      @fg0;
      border-radius:   6px;
    }

    element:selected {
      background-color: @accent;
      text-color:      @fg1;
      border-radius:   6px;
    }

    element:hover {
      background-color: @bg2;
      text-color:      @accent;
      border-radius:   6px;
    }

    element.active {
      background-color: @success;
      text-color:      @fg1;
    }

    element.urgent {
      background-color: @error;
      text-color:      @fg1;
    }
  '';

  # Note: Super+Space keybinding is set up by evremap service configured
  # in modules/nixos/sessions/cosmic.nix (system-level service)
  # evremap is a Wayland-compatible keyboard remapper that works with COSMIC
}
