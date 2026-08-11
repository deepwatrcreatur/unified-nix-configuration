# modules/home-manager/fastfetch.nix
# Dendritic Opt-in Home Manager Module for Enhanced Fastfetch System Info Summary
{ config, lib, pkgs, hostName ? "", isDesktop ? false, ... }:

let
  cfg = config.programs.fastfetch-custom;
in
{
  options.programs.fastfetch-custom = {
    enable = lib.mkEnableOption "Enhanced boxed Fastfetch system info summary for macOS and Linux";
  };

  config = lib.mkIf cfg.enable {
    programs.fastfetch = {
      enable = true;
      package = null; # Uses system fastfetch or home.packages fastfetch
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

        display = {
          color = {
            keys = "blue";
          };
          separator = "";
          constants = [
            "──────────────────────────────────────────────────────────────────────"
            "\u001b[71D"
            "\u001b[71C"
            "\u001b[70C"
            "══════════════════════════════════════════════════════════════════════"
          ];
          brightColor = false;
        };

        modules = [
          "break"
          {
            type = "version";
            key = "╔═══════════════╦═{$5}╗\u001b[55D";
            format = "\u001b[1m{#keys} {1} - {2} ";
          }
          {
            type = "os";
            key = "║  {icon}  \u001b[s{sysname}\u001b[u\u001b[10C║{$3}║{$2}";
          }
          {
            type = "kernel";
            key = "║  {icon}  Kernel    ║{$3}║{$2}";
          }
          {
            type = "datetime";
            key = "║  {icon}  Fetched   ║{$3}║{$2}";
            format = "{year}-{month-pretty}-{day-pretty} {hour-pretty}:{minute-pretty}:{second-pretty} {timezone-name}";
          }

          # Hardware Section
          {
            type = "custom";
            key = "║{#cyan}┌──────────────┬{$1}┐{#keys}║\u001b[50D";
            format = "{#bright_cyan} Hardware ";
          }
          {
            type = "memory";
            key = "║{#cyan}│ {icon}  RAM       │{$4}│{#keys}║{$2}";
          }
          {
            type = "cpu";
            key = "║{#cyan}│ {icon}  CPU       │{$4}│{#keys}║{$2}";
            showPeCoreCount = true;
          }
          {
            type = "gpu";
            key = "║{#cyan}│ {icon}  GPU       │{$4}│{#keys}║{$2}";
          }
          {
            type = "disk";
            key = "║{#cyan}│ {icon}  Disk      │{$4}│{#keys}║{$2}";
            format = "{size-used} / {size-total} ({size-percentage}) - {filesystem}";
          }
          {
            type = "custom";
            key = "║{#cyan}└──────────────┴{$1}┘{#keys}║";
            format = "";
          }

          # Desktop / Display Section
          {
            type = "custom";
            key = "║{#green}┌──────────────┬{$1}┐{#keys}║\u001b[49D";
            format = "{#bright_green} Desktop ";
          }
          {
            type = "de";
            key = "║{#green}│ {icon}  Desktop   │{$4}│{#keys}║{$2}";
          }
          {
            type = "wm";
            key = "║{#green}│ {icon}  Session   │{$4}│{#keys}║{$2}";
          }
          {
            type = "display";
            key = "║{#green}│ {icon}  Display   │{$4}│{#keys}║{$2}";
            compactType = "original-with-refresh-rate";
          }
          {
            type = "custom";
            key = "║{#green}└──────────────┴{$1}┘{#keys}║";
            format = "";
          }

          # Terminal Section
          {
            type = "custom";
            key = "║{#yellow}┌──────────────┬{$1}┐{#keys}║\u001b[50D";
            format = "{#bright_yellow} Terminal ";
          }
          {
            type = "shell";
            key = "║{#yellow}│ {icon}  Shell     │{$4}│{#keys}║{$2}";
          }
          {
            type = "terminal";
            key = "║{#yellow}│ {icon}  Terminal  │{$4}│{#keys}║{$2}";
          }
          {
            type = "packages";
            key = "║{#yellow}│ {icon}  Packages  │{$4}│{#keys}║{$2}";
          }
          {
            type = "custom";
            key = "║{#yellow}└──────────────┴{$1}┘{#keys}║";
            format = "";
          }

          # Development Toolchain Section
          {
            type = "custom";
            key = "║{#red}┌──────────────┬{$1}┐{#keys}║\u001b[51D";
            format = "{#bright_red} Development ";
          }
          {
            type = "command";
            keyIcon = "";
            key = "║{#red}│ {icon}  Rust      │{$4}│{#keys}║{$2}";
            text = "rustc --version 2>/dev/null";
            format = "rustc {~6,13}";
          }
          {
            type = "command";
            keyIcon = "";
            key = "║{#red}│ {icon}  NodeJS    │{$4}│{#keys}║{$2}";
            text = "node --version 2>/dev/null";
            format = "node {~1}";
          }
          {
            type = "command";
            keyIcon = "";
            key = "║{#red}│ {icon}  Go        │{$4}│{#keys}║{$2}";
            text = "go version 2>/dev/null | cut -d' ' -f3";
            format = "go {~2}";
          }
          {
            type = "editor";
            key = "║{#red}│ {icon}  Editor    │{$4}│{#keys}║{$2}";
          }
          {
            type = "command";
            keyIcon = "";
            key = "║{#red}│ {icon}  Git       │{$4}│{#keys}║{$2}";
            text = "git version 2>/dev/null";
            format = "git {~12}";
          }
          {
            type = "custom";
            key = "║{#red}└──────────────┴{$1}┘{#keys}║";
            format = "";
          }

          # Uptime & OS Age Section
          {
            type = "custom";
            key = "║{#magenta}┌──────────────┬{$1}┐{#keys}║\u001b[49D";
            format = "{#bright_magenta} Uptime ";
          }
          {
            type = "uptime";
            key = "║{#magenta}│ {icon}  Uptime    │{$4}│{#keys}║{$2}";
          }
          {
            condition = {
              "!system" = "macOS";
            };
            type = "disk";
            keyIcon = "";
            key = "║{#magenta}│ {icon}   OS Age    │{$4}│{#keys}║{$2}";
            folders = "/";
            format = "{create-time:10} [{days} days]";
          }
          {
            condition = {
              "system" = "macOS";
            };
            type = "disk";
            keyIcon = "";
            key = "║{#magenta}│ {icon}  OS Age    │{$4}│{#keys}║{$2}";
            folders = "/System/Volumes/VM";
            format = "{create-time:10} [{days} days]";
          }
          {
            type = "custom";
            key = "║{#magenta}└──────────────┴{$1}┘{#keys}║";
            format = "";
          }
          {
            type = "custom";
            key = "╚═════════════════{$5}╝";
            format = "";
          }
          "break"
        ];
      };
    };
  };
}
