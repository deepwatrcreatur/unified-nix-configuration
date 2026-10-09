# den/aspects/desktop-sway.nix
# Lightweight Sway tiling window manager aspect suitable for low-power kiosk and desktop nodes
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      foot
      wmenu
      fuzzel
      waybar
      wl-clipboard
      mako
      i3status
      brightnessctl
      playerctl
      pavucontrol
    ];
  };

  # Hardware graphics & video acceleration (Mesa radeonsi VA-API / OpenGL)
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  # Audio via PipeWire
  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Polkit authentication agent
  security.polkit.enable = true;

  # XDG Desktop Portals for Wayland (wlr + gtk)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "wlr" "gtk" ];
  };

  # Greetd login manager: auto-login into sway session
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.sway}/bin/sway";
        user = primaryUser;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd ${pkgs.sway}/bin/sway";
        user = "greeter";
      };
    };
  };

  users.users.${primaryUser} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "render"
      "input"
      "audio"
    ];
  };

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    extraGroups = [
      "video"
      "input"
    ];
  };
  users.groups.greeter = { };

  # Prevent conflicts with other display managers
  services.displayManager.gdm.enable = lib.mkDefault false;
  services.displayManager.sddm.enable = lib.mkDefault false;
  services.xserver.displayManager.lightdm.enable = lib.mkDefault false;

  # Home Manager Sway configuration
  home-manager.sharedModules = [
    (
      { config, lib, pkgs, ... }:
      {
        wayland.windowManager.sway = {
          enable = true;
          package = null; # Use system package from programs.sway
          config = rec {
            modifier = "Mod4"; # Super key
            terminal = "${pkgs.foot}/bin/foot";
            menu = "${pkgs.fuzzel}/bin/fuzzel";
            output = {
              "*" = {
                bg = "/run/current-system/sw/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png fill";
              };
            };
            keybindings = lib.mkOptionDefault {
              "${modifier}+b" = "exec ${pkgs.firefox}/bin/firefox";
              "Mod1+b" = "exec ${pkgs.firefox}/bin/firefox";
              "Mod1+d" = "exec ${pkgs.fuzzel}/bin/fuzzel";
              "Mod1+Return" = "exec ${pkgs.foot}/bin/foot";
            };
            bars = [ ]; # Use Waybar instead of text swaybar
            window = {
              titlebar = false;
              border = 2;
            };
            gaps = {
              inner = 4;
              outer = 4;
            };
          };
          extraConfig = ''
            # Kiosk mode: keep display awake 24/7, no screensaver or blanking
            output * dpms on

            # Launch Waybar panel
            exec ${pkgs.waybar}/bin/waybar
          '';
        };

        programs.waybar = {
          enable = true;
          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              height = 36;
              spacing = 4;
              modules-left = [
                "custom/menu"
                "custom/firefox"
                "custom/chrome"
                "custom/vivaldi"
                "custom/terminal"
                "sway/workspaces"
              ];
              modules-center = [
                "sway/window"
              ];
              modules-right = [
                "pulseaudio"
                "battery"
                "clock"
              ];
              "custom/menu" = {
                format = "☰ Apps";
                tooltip-format = "Click to open Application Menu";
                on-click = "${pkgs.fuzzel}/bin/fuzzel";
              };
              "custom/firefox" = {
                format = "Firefox";
                tooltip-format = "Click to open Firefox";
                on-click = "${pkgs.firefox}/bin/firefox";
              };
              "custom/chrome" = {
                format = "Chrome";
                tooltip-format = "Click to open Google Chrome";
                on-click = "${pkgs.google-chrome}/bin/google-chrome-stable";
              };
              "custom/vivaldi" = {
                format = "Vivaldi";
                tooltip-format = "Click to open Vivaldi";
                on-click = "${pkgs.vivaldi}/bin/vivaldi";
              };
              "custom/terminal" = {
                format = "Terminal";
                tooltip-format = "Click to open Foot Terminal";
                on-click = "${pkgs.foot}/bin/foot";
              };
              "sway/workspaces" = {
                disable-scroll = true;
                all-outputs = true;
                format = "{name}";
              };
              "sway/window" = {
                max-length = 40;
              };
              pulseaudio = {
                format = "Vol {volume}%";
                format-muted = "Muted";
                on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
              };
              battery = {
                format = "Bat {capacity}%";
              };
              clock = {
                format = "{:%a %b %d  %I:%M %p}";
                tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              };
            };
          };
          style = ''
            * {
              font-family: "DejaVu Sans", "Liberation Sans", sans-serif;
              font-size: 13px;
              min-height: 0;
            }
            window#waybar {
              background-color: #242424;
              border-bottom: 2px solid #141414;
              color: #ffffff;
            }
            #custom-menu {
              background-color: #2563eb;
              color: #ffffff;
              font-weight: bold;
              border-radius: 4px;
              padding: 3px 12px;
              margin: 3px 4px 3px 4px;
            }
            #custom-menu:hover {
              background-color: #3b82f6;
            }
            #custom-firefox, #custom-chrome, #custom-vivaldi, #custom-terminal {
              background-color: #383838;
              color: #f0f0f0;
              border-radius: 4px;
              padding: 3px 10px;
              margin: 3px 2px;
            }
            #custom-firefox:hover, #custom-chrome:hover, #custom-vivaldi:hover, #custom-terminal:hover {
              background-color: #4f4f4f;
            }
            #workspaces button {
              padding: 3px 8px;
              color: #aaaaaa;
              background-color: transparent;
              border-radius: 4px;
              margin: 3px 2px;
            }
            #workspaces button.focused {
              color: #ffffff;
              background-color: #1d4ed8;
            }
            #workspaces button.urgent {
              background-color: #dc2626;
            }
            #clock, #battery, #pulseaudio {
              padding: 3px 8px;
              color: #e0e0e0;
            }
            #pulseaudio:hover {
              background-color: #383838;
              border-radius: 4px;
            }
          '';
        };

        programs.foot = {
          enable = true;
          settings = {
            main = {
              font = "monospace:size=11";
            };
          };
        };
      }
    )
  ];
}
