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
  repoName = builtins.baseNameOf (toString ../..);

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
    # Note: sops CLI is still used for manual decryption in secrets-activation.nix
    # System-level secrets are handled by agenix at /run/agenix/
    ../../modules/home-manager/secrets-activation.nix
    ../../modules/home-manager/user-secrets.nix
    ./rbw.nix
    ./env.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone-scripts.nix
    ../../modules/home-manager
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

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
            text = "printf ${lib.escapeShellArg repoName}";
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

  programs.rclone-scripts.secretsPath = ./secrets;

  services.user-secrets = {
    enable = true;
    secretsPath = ./secrets;
  };

  home.username = "deepwatrcreatur";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc; # Remove toString, just use the path directly
  };
}
