{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zellij-extended;
  
  formatKdl = value:
    if isAttrs value then
      concatStringsSep "\n" (mapAttrsToList (k: v: "${k} ${formatKdl v}") value)
    else if isList value then
      concatStringsSep " " (map formatKdl value)
    else if isBool value then
      if value then "true" else "false"
    else if isString value then
      ''"${value}"''
    else
      toString value;

  configFile = pkgs.writeText "zellij-config.kdl" ''
    // Theme
    theme "${cfg.theme}"
    
    // Default shell
    ${optionalString (cfg.defaultShell != null) ''default_shell "${cfg.defaultShell}"''}
    
    // Default layout
    ${optionalString (cfg.defaultLayout != null) ''default_layout "${cfg.defaultLayout}"''}
    
    // Copy settings
    copy_command "${cfg.copyCommand}"
    copy_clipboard "${cfg.copyClipboard}"
    
    // Mouse mode
    mouse_mode ${if cfg.mouseMode then "true" else "false"}
    
    // Pane frames
    pane_frames ${if cfg.paneFrames then "true" else "false"}
    
    // Mirror session
    mirror_session ${if cfg.mirrorSession then "true" else "false"}
    
    // Layout directory
    ${optionalString (cfg.layoutDir != null) ''layout_dir "${cfg.layoutDir}"''}
    
    // Theme directory  
    ${optionalString (cfg.themeDir != null) ''theme_dir "${cfg.themeDir}"''}
    
    // Session serialization
    session_serialization ${if cfg.sessionSerialization then "true" else "false"}
    
    // Serialize pane viewport
    serialize_pane_viewport ${if cfg.serializePaneViewport then "true" else "false"}
    
    // Scrollback editor
    ${optionalString (cfg.scrollbackEditor != null) ''scrollback_editor "${cfg.scrollbackEditor}"''}
    
    // Auto layout
    auto_layout ${if cfg.autoLayout then "true" else "false"}
    
    // Simplified UI
    simplified_ui ${if cfg.simplifiedUi then "true" else "false"}
    
    // Default mode
    default_mode "${cfg.defaultMode}"
    
    // UI configuration
    ui {
        pane_frames {
            rounded_corners ${if cfg.ui.paneFrames.roundedCorners then "true" else "false"}
            hide_session_name ${if cfg.ui.paneFrames.hideSessionName then "true" else "false"}
        }
    }
    
    // Keybinds
    keybinds clear-defaults=${if cfg.keybinds.clearDefaults then "true" else "false"} {
        ${cfg.extraKeybinds}
    }
    
    // Plugins
    plugins {
        ${cfg.extraPlugins}
    }
    
    // Additional custom configuration
    ${cfg.extraConfig}
  '';

in {
  options.programs.zellij-extended = {
    enable = mkEnableOption "Zellij terminal multiplexer with extended configuration" // {
      default = true;
    };

    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
      description = "The Zellij package to use.";
    };

    theme = mkOption {
      type = types.str;
      default = "default";
      description = "Theme to use for Zellij.";
      example = "catppuccin-mocha";
    };

    defaultShell = mkOption {
      type = types.nullOr types.str;
      default = "${pkgs.nushell}/bin/nu";
      description = "Default shell to use in new panes.";
      example = "${pkgs.zsh}/bin/zsh";
    };

    defaultLayout = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default layout to use when starting Zellij.";
      example = "compact";
    };

    copyCommand = mkOption {
      type = types.str;
      default = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
      description = "Command used to copy to clipboard.";
      example = "xclip -selection clipboard";
    };

    copyClipboard = mkOption {
      type = types.enum [ "system" "primary" ];
      default = "system";
      description = "Clipboard to copy to.";
    };

    mouseMode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable mouse support.";
    };

    paneFrames = mkOption {
      type = types.bool;
      default = true;
      description = "Show frames around panes.";
    };

    mirrorSession = mkOption {
      type = types.bool;
      default = false;
      description = "Mirror session to all connected clients.";
    };

    layoutDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory to search for layout files.";
      example = "~/.config/zellij/layouts";
    };

    themeDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory to search for theme files.";
      example = "~/.config/zellij/themes";
    };

    sessionSerialization = mkOption {
      type = types.bool;
      default = true;
      description = "Enable session serialization on exit.";
    };

    serializePaneViewport = mkOption {
      type = types.bool;
      default = true;
      description = "Serialize pane viewport when serializing sessions.";
    };

    scrollbackEditor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Editor to use for editing scrollback.";
      example = "${pkgs.neovim}/bin/nvim";
    };

    autoLayout = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically layout new panes according to a default layout.";
    };

    simplifiedUi = mkOption {
      type = types.bool;
      default = false;
      description = "Use simplified UI (hide tab bar and status bar).";
    };

    defaultMode = mkOption {
      type = types.enum [ "normal" "locked" "resize" "pane" "tab" "scroll" "enter-search" "search" "rename-tab" "rename-pane" "session" "move" "prompt" "tmux" ];
      default = "normal";
      description = "Default mode to start in.";
    };

    ui = {
      paneFrames = {
        roundedCorners = mkOption {
          type = types.bool;
          default = true;
          description = "Use rounded corners for pane frames.";
        };

        hideSessionName = mkOption {
          type = types.bool;
          default = false;
          description = "Hide session name from pane frames.";
        };
      };
    };

    keybinds = {
      clearDefaults = mkOption {
        type = types.bool;
        default = false;
        description = "Clear default keybinds before applying custom ones.";
      };
    };

    extraKeybinds = mkOption {
      type = types.lines;
      default = if pkgs.stdenv.isDarwin then ''
        normal {
            bind "Ctrl Shift c" { Copy; }
        }
        shared_except "locked" {
            bind "Ctrl Shift c" { Copy; }
        }
      '' else "";
      description = "Extra keybind configuration in KDL format.";
      example = ''
        normal {
            bind "Alt h" { MoveFocus "Left"; }
            bind "Alt l" { MoveFocus "Right"; }
            bind "Alt j" { MoveFocus "Down"; }
            bind "Alt k" { MoveFocus "Up"; }
        }
      '';
    };

    extraPlugins = mkOption {
      type = types.lines;
      default = "";
      description = "Extra plugin configuration in KDL format.";
      example = ''
        tab-bar { path "tab-bar"; }
        status-bar { path "status-bar"; }
        strider { path "strider"; }
        compact-bar { path "compact-bar"; }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration in KDL format.";
      example = ''
        env {
            EDITOR "nvim"
            SHELL "zsh"
        }
      '';
    };

    shellIntegration = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shell integration.";
      };

      enableBashIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bash integration.";
      };

      enableZshIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Zsh integration.";
      };

      enableNushellIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nushell integration.";
      };

      enableFishIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Fish integration.";
      };
    };

    enableDesktopEntry = mkOption {
      type = types.bool;
      default = false;
      description = "Create desktop entry for Zellij (useful for rofi/application launchers).";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."zellij/config.kdl" = mkIf (cfg.enable) {
      source = configFile;
    };

    # Shell integration
    programs.bash.initExtra = mkIf (cfg.shellIntegration.enable && cfg.shellIntegration.enableBashIntegration) ''
      eval "$(${cfg.package}/bin/zellij setup --generate-completion bash)"
      eval "$(${cfg.package}/bin/zellij setup --generate-auto-start bash)"
    '';

    programs.zsh.initExtra = mkIf (cfg.shellIntegration.enable && cfg.shellIntegration.enableZshIntegration) ''
      eval "$(${cfg.package}/bin/zellij setup --generate-completion zsh)"
      eval "$(${cfg.package}/bin/zellij setup --generate-auto-start zsh)"
    '';

    programs.fish.interactiveShellInit = mkIf (cfg.shellIntegration.enable && cfg.shellIntegration.enableFishIntegration) ''
      ${cfg.package}/bin/zellij setup --generate-completion fish | source
      ${cfg.package}/bin/zellij setup --generate-auto-start fish | source
    '';

    programs.nushell.extraConfig = mkIf (cfg.shellIntegration.enable && cfg.shellIntegration.enableNushellIntegration) ''
      # Zellij completions for Nushell
      try {
        ^${cfg.package}/bin/zellij setup --generate-completion nushell | save -f ~/.cache/zellij-completion.nu
        use ~/.cache/zellij-completion.nu *
      } catch {
        # Silently ignore completion generation errors
      }
      
      # Zellij auto-start
      if (which zellij | is-empty) == false {
        if ($env | get -i ZELLIJ | is-empty) {
          if (ps | where name =~ zellij | is-empty) {
            ^${cfg.package}/bin/zellij
          }
        }
      }
    '';

    # Create a desktop entry (Linux only)
    xdg.desktopEntries.zellij = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
      name = "Zellij";
      comment = "A terminal workspace with batteries included";
      exec = "${cfg.package}/bin/zellij";
      icon = "terminal";
      terminal = true;
      categories = [ "System" "TerminalEmulator" ];
    };
  };
}
