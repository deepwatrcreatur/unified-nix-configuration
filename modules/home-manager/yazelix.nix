# modules/home-manager/yazelix.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.yazelix;
in
{
  options.programs.yazelix = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable yazelix - integrated yazi + zellij + helix setup";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.yazi;
      description = "The yazi package to use";
    };

    enableShellIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shell integration for yazelix";
    };

    enableDesktopEntry = mkOption {
      type = types.bool;
      default = false;
      description = "Create desktop entry for yazelix (Linux only)";
    };

    keymap = mkOption {
      type = types.lines;
      default = '''';
      description = "Custom keymap configuration for yazi";
    };

    theme = mkOption {
      type = types.lines;
      default = '''';
      description = "Custom theme configuration for yazi";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Yazi configuration settings";
    };

    initLua = mkOption {
      type = types.lines;
      default = '''';
      description = "Custom init.lua for yazi";
    };

    plugins = mkOption {
      type = types.attrsOf types.package;
      default = {};
      description = "Yazi plugins to install";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      cfg.package
      zellij
      helix
      # Additional tools that enhance the yazelix experience
      fd
      ripgrep
      fzf
      bat
      eza
      zoxide
      file
      mediainfo
      poppler_utils
      ffmpegthumbnailer
      unar
      jq
      miller
    ];
    
    # Shell aliases and functions for yazelix integration
    programs.bash.shellAliases = mkIf cfg.enableShellIntegration {
      yazelix = "zellij -l yazelix";
      yz = "yazi";
    };

    programs.zsh.shellAliases = mkIf cfg.enableShellIntegration {
      yazelix = "zellij -l yazelix";
      yz = "yazi";
    };

    programs.fish.shellAliases = mkIf cfg.enableShellIntegration {
      yazelix = "zellij -l yazelix";
      yz = "yazi";
    };

    # Yazi configuration
    programs.yazi = {
      enable = true;
      package = cfg.package;
      enableBashIntegration = cfg.enableShellIntegration;
      enableZshIntegration = cfg.enableShellIntegration;
      enableFishIntegration = cfg.enableShellIntegration;
      
      settings = recursiveUpdate {
        manager = {
          show_hidden = false;
          show_symlink = true;
          scrolloff = 5;
        };
        preview = {
          tab_size = 2;
          max_width = 600;
          max_height = 900;
        };
        opener = {
          edit = [
            { run = ''helix "$@"''; block = true; for = "unix"; }
          ];
          open = [
            { run = ''${if pkgs.stdenv.isLinux then "xdg-open" else "open"} "$@"''; desc = "Open"; }
          ];
        };
        open = {
          rules = [
            { name = "*/"; use = [ "edit" "open" "reveal" ]; }
            { mime = "text/*"; use = [ "edit" "reveal" ]; }
            { mime = "image/*"; use = [ "open" "reveal" ]; }
            { mime = "video/*"; use = [ "play" "reveal" ]; }
            { mime = "audio/*"; use = [ "play" "reveal" ]; }
            { mime = "inode/x-empty"; use = [ "edit" "reveal" ]; }
          ];
        };
      } cfg.settings;

      keymap = mkIf (cfg.keymap != "") {
        manager.prepend_keymap = [
          { on = [ "g" "h" ]; run = "cd ~"; desc = "Go to home directory"; }
          { on = [ "g" "c" ]; run = "cd ~/.config"; desc = "Go to config directory"; }
          { on = [ "g" "d" ]; run = "cd ~/Downloads"; desc = "Go to downloads"; }
          { on = [ "g" "D" ]; run = "cd ~/Documents"; desc = "Go to documents"; }
          { on = [ "g" "p" ]; run = "cd ~/Projects"; desc = "Go to projects"; }
          { on = [ "<C-s>" ]; run = "search fd"; desc = "Search files with fd"; }
          { on = [ "<C-f>" ]; run = "search rg"; desc = "Search content with ripgrep"; }
          { on = [ "T" ]; run = "plugin --sync smart-enter"; desc = "Enter hovered directory or open file"; }
        ];
      };

      theme = mkIf (cfg.theme != "") cfg.theme;

      initLua = ''
        -- Custom yazelix init.lua
        require("full-border"):setup()
        require("git"):setup()
        
        ${cfg.initLua}
      '';
    };

    # Install yazi plugins and zellij layout
    xdg.configFile = lib.mkMerge [
      # Yazi plugins
      (lib.mkMerge (
        lib.mapAttrsToList (name: plugin: {
          "yazi/plugins/${name}" = {
            source = plugin;
            recursive = true;
          };
        }) cfg.plugins
      ))
      
      # Zellij layout for yazelix
      {
        "zellij/layouts/yazelix.kdl" = {
          text = ''
            layout {
              pane size=1 borderless=true {
                plugin location="zellij:tab-bar"
              }
              pane split_direction="vertical" {
                pane size="30%" {
                  command "yazi"
                }
                pane split_direction="horizontal" {
                  pane {
                    command "helix"
                    args "."
                  }
                  pane size="30%" {
                    // Terminal pane for commands
                  }
                }
              }
              pane size=2 borderless=true {
                plugin location="zellij:status-bar"
              }
            }
          '';
        };
      }
    ];

    # Desktop entry for yazelix (Linux only)
    xdg.desktopEntries.yazelix = mkIf (cfg.enableDesktopEntry && pkgs.stdenv.isLinux) {
      name = "Yazelix";
      comment = "Integrated file manager and editor";
      exec = "zellij -l yazelix";
      icon = "folder";
      terminal = true;
      categories = [ "Development" "FileManager" ];
    };

    # Install additional tools via cargo-binstall if needed
    home.activation.installYazelixTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Ensure ~/.cargo/bin exists
      mkdir -p "$HOME/.cargo/bin"
      
      # Install additional yazi tools if not available via nixpkgs
      if ! command -v ya >/dev/null 2>&1; then
        "${pkgs.cargo-binstall}/bin/cargo-binstall" \
          yazi-cli \
          --force --no-confirm || true
      fi
      
      # Update all cargo-installed tools
      if command -v cargo-update >/dev/null 2>&1; then
        "${pkgs.rustc}/bin/cargo" install-update -a || true
      fi
    '';
  };
}
