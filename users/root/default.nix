{
  config,
  pkgs,
  lib,
  inputs,
  hostName ? "",
  isDesktop ? false,
  ...
}:
let
  inherit (lib) optionals;

  desktopModules = [
    {
      type = "custom";
      format = "DESKTOP";
      outputColor = "cyan";
    }
    {
      type = "de";
      key = "󰧨 DE";
      keyColor = "cyan";
      keyWidth = 16;
    }
    {
      type = "wm";
      key = "󱂬 WM";
      keyColor = "cyan";
      keyWidth = 16;
    }
    {
      type = "display";
      key = "󰍹 Display";
      keyColor = "cyan";
      keyWidth = 16;
      compactType = "original-with-refresh-rate";
      format = "{width}x{height} @ {refresh-rate} Hz";
    }
    {
      type = "terminal";
      key = " Terminal";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}";
    }
    {
      type = "terminalfont";
      key = "󰛖 Font";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{name}{?size} [{size}]{?}";
    }
    {
      type = "localip";
      key = "󰩠 Local IP";
      keyColor = "cyan";
      keyWidth = 16;
      compact = true;
    }
  ];

  headlessModules = [
    {
      type = "custom";
      format = "ACCESS";
      outputColor = "cyan";
    }
    {
      type = "shell";
      key = "󰆍 Shell";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}{?version} [v{version}]{?}";
    }
    {
      type = "terminal";
      key = " Terminal";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}";
    }
    {
      type = "localip";
      key = "󰩠 Local IP";
      keyColor = "cyan";
      keyWidth = 16;
      compact = true;
    }
  ];
in
{
  imports = [
    ./sops.nix # <--- Temporarily disabled sops configuration
    ./git.nix # <--- Import git configuration
    ./env.nix
    ../../modules/home-manager/git.nix # Keep this import if it provides other common git modules
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.fastfetch = {
    enable = true;
    package = null;
    settings = {
      display = {
        separator = "  ";
        constants = [ "         " ];
        color = {
          keys = "default";
          title = "cyan";
          output = "default";
        };
        percent.type = [ "num" "bar" ];
        bar = {
          width = 15;
          char = {
            elapsed = "■";
            total = "·";
          };
          color = {
            elapsed = "cyan";
            total = "bright_black";
          };
        };
      };

      modules =
        [
          "title"
          {
            type = "custom";
            format = "IDENTITY";
            outputColor = "blue";
          }
          {
            type = "command";
            key = "󰘵 Profile";
            keyColor = "blue";
            keyWidth = 16;
            text = "printf '%s' '${if isDesktop then "desktop" else "headless"}'";
          }
          {
            type = "command";
            key = "󰌘 Leaf";
            keyColor = "blue";
            keyWidth = 16;
            text = "printf '%s' '${hostName}'";
          }
          {
            type = "custom";
            format = "SYSTEM";
            outputColor = "green";
          }
          {
            type = "os";
            key = "󰣇 OS";
            keyColor = "green";
            keyWidth = 16;
            format = "{?pretty-name}{pretty-name}{?}{name} [{arch}]";
          }
          {
            type = "host";
            key = "󰌢 Machine";
            keyColor = "green";
            keyWidth = 16;
            format = "{name}{?version} [{version}]{?}";
          }
          {
            type = "kernel";
            key = "󰒋 Kernel";
            keyColor = "green";
            keyWidth = 16;
            format = "{sysname} {release}";
          }
          {
            type = "uptime";
            key = "󰔛 Uptime";
            keyColor = "green";
            keyWidth = 16;
            format = "{?days}{days}d {?}{hours}h {minutes}m";
          }
          {
            type = "packages";
            key = "󰏖 Packages";
            keyColor = "green";
            keyWidth = 16;
            format = "{all}";
          }
          {
            type = "custom";
            format = "HARDWARE";
            outputColor = "yellow";
          }
          {
            type = "cpu";
            key = "󰍛 CPU";
            keyColor = "yellow";
            keyWidth = 16;
            format = "{name}";
            showPeCoreCount = true;
          }
          {
            type = "gpu";
            key = "󰢮 GPU";
            keyColor = "yellow";
            keyWidth = 16;
            format = "{name}";
          }
          {
            type = "memory";
            key = "󰑭 Memory";
            keyColor = "yellow";
            keyWidth = 16;
            format = "{percentage-bar} {used} / {total}";
          }
          {
            type = "swap";
            key = "󰓡 Swap";
            keyColor = "yellow";
            keyWidth = 16;
            format = "{used} / {total}";
          }
          {
            type = "disk";
            key = "󰋊 Root";
            keyColor = "yellow";
            keyWidth = 16;
            folders = "/";
            format = "{size-percentage-bar} {size-used} / {size-total}";
          }
        ]
        ++ optionals isDesktop desktopModules
        ++ optionals (!isDesktop) headlessModules
        ++ [
          {
            type = "custom";
            format = "CONTEXT";
            outputColor = "magenta";
          }
          {
            type = "command";
            key = "󰑓 Flake";
            keyColor = "magenta";
            keyWidth = 16;
            text = "basename ~/flakes/unified-nix-configuration 2>/dev/null || printf unified-nix-configuration";
          }
          {
            type = "datetime";
            key = "󰃰 Time";
            keyColor = "magenta";
            keyWidth = 16;
            format = "{year}-{month-pretty}-{day-pretty} {hour-pretty}:{minute-pretty}";
          }
          {
            type = "shell";
            key = "󰆍 Shell";
            keyColor = "magenta";
            keyWidth = 16;
            format = "{pretty-name}{?version} [v{version}]{?}";
          }
          {
            type = "colors";
            key = "󰏘 Palette";
            keyColor = "magenta";
            keyWidth = 16;
            symbol = "circle";
          }
        ];
    };
  };
}
