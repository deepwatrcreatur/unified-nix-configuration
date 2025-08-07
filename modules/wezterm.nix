{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.wezterm;
  
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  
  # Default configuration that works well on both platforms
  defaultConfig = ''
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
    
    -- Tab configuration
    config.enable_tab_bar = ${boolToString cfg.tabs.enable}
    config.hide_tab_bar_if_only_one_tab = ${boolToString cfg.tabs.hideIfOnlyOne}
    config.tab_bar_at_bottom = ${boolToString cfg.tabs.atBottom}
    
    -- Platform-specific settings
    ${optionalString isDarwin ''
    -- macOS specific settings
    config.native_macos_fullscreen_mode = ${boolToString cfg.macos.nativeFullscreen}
    config.send_composed_key_when_left_alt_is_pressed = ${boolToString cfg.macos.leftAltComposed}
    config.send_composed_key_when_right_alt_is_pressed = ${boolToString cfg.macos.rightAltComposed}
    ''}
    
    ${optionalString isLinux ''
    -- Linux specific settings
    config.enable_wayland = ${boolToString cfg.linux.enableWayland}
    ''}
    
    -- Key bindings
    config.keys = {
      ${concatStringsSep ",\n      " (map (binding: 
        "{ key = '${binding.key}', mods = '${binding.mods}', action = wezterm.action.${binding.action} }"
      ) cfg.keyBindings)}
    }
    
    -- Custom configuration
    ${cfg.extraConfig}
    
    return config
  '';
  
  configFile = pkgs.writeText "wezterm.lua" defaultConfig;
  
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
    
    # macOS specific options
    macos = mkOption {
      type = types.submodule {
        options = {
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
        };
      };
      default = {};
      description = "macOS specific configuration";
    };
    
    # Linux specific options  
    linux = mkOption {
      type = types.submodule {
        options = {
          enableWayland = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Wayland support on Linux";
          };
        };
      };
      default = {};
      description = "Linux specific configuration";
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
    
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra Lua configuration to append";
    };
  };
  
  config = mkIf cfg.enable {
    # Install Wezterm package
    environment.systemPackages = [ cfg.package ];
    
    # Create config file in appropriate location
    environment.etc = mkIf isDarwin {
      "wezterm/wezterm.lua".source = configFile;
    };
    
    # For NixOS systems, place config in system location
    environment.etc = mkIf isLinux {
      "wezterm/wezterm.lua".source = configFile;
    };
    
    # Home Manager integration (works on both platforms)
    # This assumes home-manager is available as a NixOS module
    home-manager.sharedModules = mkIf (hasAttr "home-manager" config) [{
      home.file.".config/wezterm/wezterm.lua".source = configFile;
    }];
    
    # Font packages (useful for both platforms)
    fonts.packages = with pkgs; [
      jetbrains-mono
      fira-code
      source-code-pro
      hack-font
    ];
  };
}
