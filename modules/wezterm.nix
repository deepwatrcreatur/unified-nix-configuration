# modules/wezterm.nix - Home Manager module
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.wezterm;

  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

in {
  options.programs.wezterm = {
    enable = mkEnableOption "Wezterm terminal emulator";

    package = mkOption {
      type = types.package;
      default = pkgs.wezterm;
      description = "The Wezterm package to use";
    };

    font = {
      name = mkOption {
        type = types.str;
        default = "JetBrains Mono";
        description = "Font family name";
      };

      size = mkOption {
        type = types.float;
        default = 12.0;
        description = "Font size";
      };

      weight = mkOption {
        type = types.str;
        default = "Regular";
        description = "Font weight";
      };
    };

    colorScheme = mkOption {
      type = types.str;
      default = "Tokyo Night";
      description = "Color scheme name";
    };

    window = {
      opacity = mkOption {
        type = types.float;
        default = 1.0;
        description = "Window background opacity (0.0 to 1.0)";
      };

      decorations = mkOption {
        type = types.enum [ "TITLE" "NONE" "RESIZE" "TITLE | RESIZE" ];
        default = "TITLE | RESIZE";
        description = "Window decorations";
      };

      closeConfirmation = mkOption {
        type = types.enum [ "AlwaysPrompt" "CloseOnCleanExit" "NeverPrompt" ];
        default = "AlwaysPrompt";
        description = "Window close confirmation behavior";
      };

      adjustSizeWhenChangingFont = mkOption {
        type = types.bool;
        default = true;
        description = "Adjust window size when changing font size";
      };
    };

    tabs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tab bar";
      };

      hideIfOnlyOne = mkOption {
        type = types.bool;
        default = true;
        description = "Hide tab bar if only one tab is open";
      };

      atBottom = mkOption {
        type = types.bool;
        default = false;
        description = "Place tab bar at bottom";
      };
    };

    scrollbackLines = mkOption {
      type = types.int;
      default = 3000;
      description = "Number of lines of scrollback to keep";
    };

    # macOS specific options
    macos = {
      nativeFullscreen = mkOption {
        type = types.bool;
        default = false;
        description = "Use native macOS fullscreen mode";
      };

      leftAltComposed = mkOption {
        type = types.bool;
        default = false;
        description = "Send composed key when left alt is pressed";
      };

      rightAltComposed = mkOption {
        type = types.bool;
        default = true;
        description = "Send composed key when right alt is pressed";
      };

      windowBackgroundBlur = mkOption {
        type = types.int;
        default = 0;
        description = "Window background blur amount (macOS only, 0 disables)";
      };
    };

    # Linux specific options
    linux = {
      enableWayland = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wayland support on Linux";
      };
    };

    keyBindings = mkOption {
      type = types.listOf (types.submodule {
        options = {
          key = mkOption {
            type = types.str;
            description = "Key to bind";
          };

          mods = mkOption {
            type = types.str;
            default = "";
            description = "Modifiers (CTRL, ALT, SHIFT, SUPER)";
          };

          action = mkOption {
            type = types.str;
            description = "Action to perform";
          };
        };
      });
      default = [
        { key = "t"; mods = "CTRL|SHIFT"; action = "SpawnTab 'CurrentPaneDomain'"; }
        { key = "w"; mods = "CTRL|SHIFT"; action = "CloseCurrentTab { confirm = true }"; }
        { key = "n"; mods = "CTRL|SHIFT"; action = "SpawnWindow"; }
      ];
      description = "Custom key bindings";
    };

    mouseBindings = mkOption {
      type = types.listOf (types.submodule {
        options = {
          event = mkOption {
            type = types.str;
            description = "Mouse event (e.g., 'Up = { streak = 1, button = \"Left\" }')";
          };

          mods = mkOption {
            type = types.str;
            default = "";
            description = "Modifiers (CTRL, ALT, SHIFT, SUPER)";
          };

          action = mkOption {
            type = types.str;
            description = "Action to perform";
          };
        };
      });
      default = [];
      description = "Mouse bindings";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra Lua configuration to append";
    };
  };

  config = mkIf cfg.enable {
    # Install Wezterm package at system level
    environment.systemPackages = [ cfg.package ];

    # Font packages (useful for both platforms)
    fonts.packages = with pkgs; [
      # jetbrains-mono  # Temporarily commented out due to build issues
      fira-code
      source-code-pro
      hack-font
    ];

    # Home Manager configuration for all users
    home-manager.sharedModules = [{
      home.file.".config/wezterm/wezterm.lua".text = ''
        local wezterm = require 'wezterm'
        local config = wezterm.config_builder()

        -- Font configuration
        config.font = wezterm.font('${cfg.font.name}', { weight = '${cfg.font.weight}' })
        config.font_size = ${toString cfg.font.size}

        -- Color scheme
        config.color_scheme = '${cfg.colorScheme}'

        -- Window configuration
        config.window_background_opacity = ${toString cfg.window.opacity}
        config.window_decorations = '${cfg.window.decorations}'
        config.window_close_confirmation = '${cfg.window.closeConfirmation}'
        config.adjust_window_size_when_changing_font_size = ${boolToString cfg.window.adjustSizeWhenChangingFont}

        -- Tab configuration
        config.enable_tab_bar = ${boolToString cfg.tabs.enable}
        config.hide_tab_bar_if_only_one_tab = ${boolToString cfg.tabs.hideIfOnlyOne}
        config.tab_bar_at_bottom = ${boolToString cfg.tabs.atBottom}

        -- Scrollback configuration
        config.scrollback_lines = ${toString cfg.scrollbackLines}

        ${optionalString isDarwin ''
        -- macOS specific settings
        config.native_macos_fullscreen_mode = ${boolToString cfg.macos.nativeFullscreen}
        config.send_composed_key_when_left_alt_is_pressed = ${boolToString cfg.macos.leftAltComposed}
        config.send_composed_key_when_right_alt_is_pressed = ${boolToString cfg.macos.rightAltComposed}
        ${optionalString (cfg.macos.windowBackgroundBlur > 0) ''
        config.macos_window_background_blur = ${toString cfg.macos.windowBackgroundBlur}
        ''}
        ''}

        ${optionalString isLinux ''
        -- Linux specific settings
        config.enable_wayland = ${boolToString cfg.linux.enableWayland}
        ''}

        -- Key bindings
        config.keys = {
        ${concatStringsSep ",\n        " (filter (s: s != "") (map (binding:
          let
            modsStr = if binding.mods != "" then ", mods = '${binding.mods}'" else "";
          in
            "{ key = '${binding.key}'${modsStr}, action = wezterm.action.${binding.action} }"
        ) cfg.keyBindings))}
        }

        ${optionalString (cfg.mouseBindings != []) ''
        -- Mouse bindings  
        config.mouse_bindings = {
        ${concatStringsSep ",\n        " (filter (s: s != "") (map (binding:
          let
            modsStr = if binding.mods != "" then ", mods = '${binding.mods}'" else "";
          in
            "{ event = { ${binding.event} }${modsStr}, action = wezterm.action.${binding.action} }"
        ) cfg.mouseBindings))}
        }
        ''}

        -- Custom configuration
        ${cfg.extraConfig}

        return config
      '';
    }];
  };
}
