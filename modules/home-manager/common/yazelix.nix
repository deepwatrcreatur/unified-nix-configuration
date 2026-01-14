# modules/home-manager/yazelix.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.programs.yazelix;
  # Fetch zjstatus wasm directly since it's not in nixpkgs
  zjstatus-wasm = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.17.0/zjstatus.wasm";
    sha256 = "1rbvazam9qdj2z21fgzjvbyp5mcrxw28nprqsdzal4dqbm5dy112";
  };
in
{
  options.programs.yazelix = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable yazelix - integrated yazi + helix setup";
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

    keymap = mkOption {
      type = types.lines;
      default = "";
      description = "Custom keymap configuration for yazi";
    };

    theme = mkOption {
      type = types.lines;
      default = "";
      description = "Custom theme configuration for yazi";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Yazi configuration settings";
    };

    initLua = mkOption {
      type = types.lines;
      default = "";
      description = "Custom init.lua for yazi";
    };

    plugins = mkOption {
      type = types.attrsOf types.package;
      default = { };
      description = "Yazi plugins to install";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages for yazi functionality
    home.packages = with pkgs; [
      cfg.package
      # File management and preview tools
      zellij
      eza
      file
      mediainfo
      poppler-utils
      ffmpegthumbnailer
      unar
      miller
    ];

    # Shell aliases for yazelix
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

    # Yazi configuration optimized for helix integration
    programs.yazi = {
      enable = true;
      inherit (cfg) package;
      enableBashIntegration = cfg.enableShellIntegration;
      enableZshIntegration = cfg.enableShellIntegration;
      enableFishIntegration = cfg.enableShellIntegration;

      settings = recursiveUpdate {
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
              run = ''hx "$@"'';
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
      } cfg.settings;

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
        ++ (if cfg.keymap != "" then lib.strings.splitString "\n" cfg.keymap else [ ]);
      };

      theme = mkIf (cfg.theme != "") cfg.theme;

      initLua = ''
        -- Yazelix init.lua for helix integration
        ${cfg.initLua}
      '';
    };

    # Install yazi plugins and yazelix zellij layout
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

      # Yazelix Zellij Layout with enhanced theming
      {
        "zellij/layouts/yazelix.kdl" = {
          text = ''
            layout {
                // Enhanced tab bar with custom theming
                pane size=1 borderless=true {
                    plugin location="file:${zjstatus-wasm}" {
                        ${if inputs ? zellij-vivid-rounded then inputs.zellij-vivid-rounded.lib.topBar else ""}
                    }
                }
                pane split_direction="vertical" {
                    // File manager pane - labeled for clarity
                    pane size="30%" {
                        command "yazi"
                        name "📁 File Manager"
                    }
                    pane split_direction="horizontal" {
                        // Editor pane - labeled
                        pane {
                            command "hx"
                            args "."
                            name "📝 Editor"
                        }
                        // Terminal pane - labeled with working directory hint
                        pane size="30%" {
                            // Terminal pane for commands, git, etc.
                            name "💻 Terminal"
                        }
                    }
                }
                // Enhanced status bar with working directory
                pane size=2 borderless=true {
                    plugin location="file:${zjstatus-wasm}" {
                        ${
                          if inputs ? zellij-vivid-rounded then inputs.zellij-vivid-rounded.lib.bottomBar else ""
                        }
                    }
                }
            }
          '';
        };
      }
    ];
  };
}
