# modules/home-manager/common/yazelix-enhanced.nix
# Enhanced yazelix setup that preserves your custom configuration
# Note: Upstream yazelix has moved to devenv-based approach, so we enhance the existing module
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.programs.yazelix-enhanced;
in
{
  options.programs.yazelix-enhanced = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable enhanced yazelix with additional tools and integrations";
    };

    enableShellIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shell integration for yazelix";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to include with yazelix";
    };

    customKeybinds = mkOption {
      type = types.lines;
      default = "";
      description = "Custom keybinds to add to yazi configuration";
    };

    editor = mkOption {
      type = types.str;
      default = "hx";
      description = "Editor command to use with yazelix";
    };

    enableDevenv = mkOption {
      type = types.bool;
      default = false;
      description = "Enable devenv-based yazelix (requires manual setup)";
    };
  };

  config = mkIf cfg.enable {
    # Use your existing yazelix module with enhancements
    programs.yazelix = {
      enable = true;
      enableShellIntegration = cfg.enableShellIntegration;
      package = pkgs.yazi;
      
      # Enhanced settings with your customizations
      settings = {
        mgr = {
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
            {
              run = ''${cfg.editor} "$@"'';
              block = true;
              for = "unix";
            }
          ];
          open = [
            {
              run = ''${if pkgs.stdenv.isLinux then "xdg-open" else "open"} "$@"'';
              desc = "Open";
            }
          ];
        };
        open = {
          rules = [
            {
              name = "*/";
              use = [
                "edit"
                "open"
                "reveal"
              ];
            }
            {
              mime = "text/*";
              use = [
                "edit"
                "reveal"
              ];
            }
            {
              mime = "image/*";
              use = [
                "open"
                "reveal"
              ];
            }
            {
              mime = "video/*";
              use = [
                "play"
                "reveal"
              ];
            }
            {
              mime = "audio/*";
              use = [
                "play"
                "reveal"
              ];
            }
            {
              mime = "inode/x-empty";
              use = [
                "edit"
                "reveal"
              ];
            }
          ];
        };
      };

      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "g"
              "h"
            ];
            run = "cd ~";
            desc = "Go to home directory";
          }
          {
            on = [
              "g"
              "c"
            ];
            run = "cd ~/.config";
            desc = "Go to config directory";
          }
          {
            on = [
              "g"
              "d"
            ];
            run = "cd ~/Downloads";
            desc = "Go to downloads";
          }
          {
            on = [
              "g"
              "D"
            ];
            run = "cd ~/Documents";
            desc = "Go to documents";
          }
          {
            on = [
              "g"
              "p"
            ];
            run = "cd ~/Projects";
            desc = "Go to projects";
          }
          {
            on = [ "<C-s>" ];
            run = "search fd";
            desc = "Search files with fd";
          }
          {
            on = [ "<C-f>" ];
            run = "search rg";
            desc = "Search content with ripgrep";
          }
          {
            on = [ "T" ];
            run = "plugin --sync smart-enter";
            desc = "Enter hovered directory or open file";
          }
        ]
        ++ (if cfg.customKeybinds != "" then lib.strings.splitString "\n" cfg.customKeybinds else [ ]);
      };

      initLua = ''
        -- Enhanced yazelix init.lua for better integration
        -- Add your custom Lua enhancements here
      '';
    };

    # Enhanced shell aliases
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

    programs.nushell.shellAliases = mkIf cfg.enableShellIntegration {
      yazelix = "zellij -l yazelix";
      yz = "yazi";
    };

    # Install enhanced package set
    home.packages = with pkgs; [
      # Core yazelix functionality
      yazi
      zellij
      eza
      file
      mediainfo
      poppler-utils
      ffmpegthumbnailer
      unar
      miller
      
      # Additional tools
      fd
      ripgrep
      fzf
      zoxide
      starship
      lazygit
    ] ++ cfg.extraPackages;

    # Enhanced Helix integration
    programs.helix.settings = {
      keys.normal = {
        # Yazelix sidebar integration - reveal current file in Yazi sidebar
        "A-y" = ":sh nu ~/.config/yazelix/nushell/scripts/integrations/reveal_in_yazi.nu \"%{buffer_name}\"";
      };
    };

    # Install yazelix zellij layout
    xdg.configFile = {
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
                          command "${cfg.editor}"
                          args "."
                      }
                      pane size="30%" {
                          // Terminal pane for commands, git, etc.
                      }
                  }
              }
              pane size=2 borderless=true {
                  plugin location="zellij:status-bar"
              }
          }
        '';
      };
    };
  };
}