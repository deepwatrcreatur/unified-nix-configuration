# modules/nixos/sessions/noctalia-niri.nix
# Reusable NixOS session module for Niri scrollable-tiling Wayland compositor
# and Noctalia v5 desktop shell (bar, launcher, lockscreen, notification center).
# Can be imported by any NixOS host in profiles or configuration.nix.

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  primaryUser = config.host.primaryUser or "deepwatrcreatur";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # ✦ SYSTEM LEVEL CONFIGURATION ✦

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  environment.systemPackages = [
    noctaliaPkg
    pkgs.xwayland-satellite
    pkgs.wl-clipboard
    pkgs.libnotify
    pkgs.pavucontrol
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.foot
    pkgs.alacritty
    pkgs.xdg-utils
    pkgs.cava
    pkgs.networkmanagerapplet
    pkgs.cliphist
  ];

  # Hardware acceleration
  hardware.graphics.enable = lib.mkDefault true;

  # Audio via PipeWire
  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Polkit authentication agent
  security.polkit.enable = true;

  # XDG Desktop Portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "gnome" "gtk" ];
  };

  # Greetd login manager: auto-login into Niri session with tuigreet fallback
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = primaryUser;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
    };
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

  # ✦ HOME-MANAGER INTEGRATION ✦
  home-manager.sharedModules = [
    inputs.niri.homeModules.config
    inputs.noctalia.homeModules.default
    (
      { config, lib, pkgs, ... }:
      {
        # Niri Settings
        programs.niri = {
          package = pkgs.niri;

          settings = {
            prefer-no-csd = true;

            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  options = "caps:escape";
                };
                repeat-delay = 250;
                repeat-rate = 35;
              };
              touchpad = {
                tap = true;
                natural-scroll = true;
                accel-speed = 0.2;
              };
              mouse = {
                accel-speed = 0.0;
              };
              focus-follows-mouse.enable = true;
              warp-mouse-to-focus.enable = false;
            };

            output."HDMI-A-1" = {
              mode = {
                width = 3840;
                height = 2160;
                refresh = 60.0;
              };
              scale = 1.5;
              position = {
                x = 0;
                y = 0;
              };
            };

            layout = {
              gaps = 12;
              center-focused-column = "never";
              always-center-single-column = true;
              empty-workspace-above-first = false;

              default-column-width = {
                proportion = 0.5;
              };

              focus-ring = {
                enable = true;
                width = 2.0;
                active = {
                  color = "#7aa2f7";
                };
                inactive = {
                  color = "#1a1b2680";
                };
              };

              border = {
                enable = true;
                width = 1.0;
                active = {
                  color = "#3b4261";
                };
                inactive = {
                  color = "#16161e";
                };
              };

              shadow = {
                enable = true;
                softness = 30;
                spread = 4;
                offset = {
                  x = 0;
                  y = 6;
                };
                color = "#00000066";
              };

              struts = {
                top = 40;
                bottom = 0;
                left = 0;
                right = 0;
              };
            };

            animations = {
              slowdown = 1.0;
              workspace-switch = {
                spring = {
                  damping-ratio = 0.85;
                  stiffness = 800;
                  epsilon = 0.0001;
                };
              };
              horizontal-view-movement = {
                spring = {
                  damping-ratio = 0.85;
                  stiffness = 800;
                  epsilon = 0.0001;
                };
              };
              window-open = {
                duration-ms = 200;
                curve = "ease-out-cubic";
              };
              window-close = {
                duration-ms = 150;
                curve = "ease-out-quad";
              };
              window-movement = {
                spring = {
                  damping-ratio = 0.85;
                  stiffness = 800;
                  epsilon = 0.0001;
                };
              };
            };

            window-rules = [
              {
                geometry-corner-radius = {
                  bottom-left = 12.0;
                  bottom-right = 12.0;
                  top-left = 12.0;
                  top-right = 12.0;
                };
                clip-to-geometry = true;
              }
              {
                matches = [
                  { app-id = "^org\\.wezfurlong\\.wezterm$"; }
                  { app-id = "^foot$"; }
                  { app-id = "^Alacritty$"; }
                ];
                default-column-width = { proportion = 0.5; };
              }
              {
                matches = [
                  { app-id = "^google-chrome$"; }
                  { app-id = "^firefox$"; }
                  { app-id = "^zen-alpha$"; }
                  { app-id = "^vivaldi.*"; }
                ];
                default-column-width = { proportion = 0.65; };
              }
              {
                matches = [
                  { app-id = "^pavucontrol$"; }
                  { app-id = "^nm-connection-editor$"; }
                  { app-id = "^blueman-manager$"; }
                ];
                open-floating = true;
              }
            ];

            layer-rules = [
              {
                matches = [ { namespace = "^noctalia-wallpaper.*"; } ];
                place-within-backdrop = true;
              }
              {
                matches = [ { namespace = "^noctalia-backdrop.*"; } ];
                place-within-backdrop = true;
              }
              {
                matches = [ { namespace = "^noctalia-notification.*"; } ];
                block-out-from = "screencast";
              }
              {
                matches = [ { namespace = "^noctalia-osd.*"; } ];
                block-out-from = "screencast";
              }
            ];

            spawn-at-startup = [
              { command = [ "${pkgs.xwayland-satellite}/bin/xwayland-satellite" ]; }
              { command = [ "${noctaliaPkg}/bin/noctalia" ]; }
            ];

            binds = {
              "Mod+Return".action.spawn = [ "${pkgs.foot}/bin/foot" ];
              "Mod+T".action.spawn = [ "${pkgs.alacritty}/bin/alacritty" ];
              "Mod+B".action.spawn = [ "${pkgs.google-chrome}/bin/google-chrome-stable" ];
              "Mod+E".action.spawn = [ "${pkgs.xdg-utils}/bin/xdg-open" (config.home.homeDirectory or "/home/deepwatrcreatur") ];

              # Noctalia Panel & IPC controls
              "Mod+Space".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "launcher"
              ];
              "Mod+C".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "control-center"
              ];
              "Mod+V".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "clipboard"
              ];
              "Mod+N".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "notifications"
              ];
              "Mod+Escape".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "session"
                "lock"
              ];
              "Mod+Shift+P".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "session"
              ];
              "Mod+Shift+W".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "wallpaper"
                "cycle"
              ];

              # Window management
              "Mod+Q".action.close-window = [ ];
              "Mod+Left".action.focus-column-left = [ ];
              "Mod+Right".action.focus-column-right = [ ];
              "Mod+Up".action.focus-window-up = [ ];
              "Mod+Down".action.focus-window-down = [ ];
              "Mod+Shift+Left".action.move-column-left = [ ];
              "Mod+Shift+Right".action.move-column-right = [ ];
              "Mod+Shift+Up".action.move-window-up = [ ];
              "Mod+Shift+Down".action.move-window-down = [ ];

              "Mod+Home".action.focus-column-first = [ ];
              "Mod+End".action.focus-column-last = [ ];

              "Mod+F".action.maximize-column = [ ];
              "Mod+Shift+F".action.fullscreen-window = [ ];
              "Mod+R".action.switch-preset-column-width = [ ];

              "Mod+Minus".action.set-column-width = "-10%";
              "Mod+Equal".action.set-column-width = "+10%";

              # Workspaces
              "Mod+1".action.focus-workspace = 1;
              "Mod+2".action.focus-workspace = 2;
              "Mod+3".action.focus-workspace = 3;
              "Mod+4".action.focus-workspace = 4;
              "Mod+5".action.focus-workspace = 5;

              "Mod+Shift+1".action.move-column-to-workspace = 1;
              "Mod+Shift+2".action.move-column-to-workspace = 2;
              "Mod+Shift+3".action.move-column-to-workspace = 3;
              "Mod+Shift+4".action.move-column-to-workspace = 4;
              "Mod+Shift+5".action.move-column-to-workspace = 5;

              # Media / Audio
              "XF86AudioRaiseVolume".action.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];
              "XF86AudioLowerVolume".action.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
              "XF86AudioMute".action.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
              "XF86AudioPlay".action.spawn = [ "${pkgs.playerctl}/bin/playerctl" "play-pause" ];
              "XF86AudioNext".action.spawn = [ "${pkgs.playerctl}/bin/playerctl" "next" ];
              "XF86AudioPrev".action.spawn = [ "${pkgs.playerctl}/bin/playerctl" "previous" ];
              "XF86MonBrightnessUp".action.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "set" "5%+" ];
              "XF86MonBrightnessDown".action.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "set" "5%-" ];
            };
          };
        };

        # Noctalia Settings
        programs.noctalia = {
          enable = true;
          package = noctaliaPkg;

          settings = {
            shell = {
              font_family = "JetBrainsMono Nerd Font";
              ui_scale = 1.0;
              corner_radius_scale = 1.2;
              avatar_path = "~/.face";
              telemetry_enabled = false;
              clipboard_enabled = true;
              clipboard_auto_paste = "off";
              time_format = "{:%I:%M %p}";
              date_format = "%A, %d %B";

              animation = {
                enabled = true;
                speed = 1.0;
              };

              shadow = {
                direction = "down";
                alpha = 0.65;
              };

              panel = {
                transparency_mode = "glass";
                borders = true;
                shadow = true;
                launcher_placement = "floating";
                launcher_position = "center";
                clipboard_placement = "floating";
                clipboard_position = "center";
                control_center_placement = "floating";
                session_placement = "floating";
                session_position = "center";
                floating_offset = 10;
                open_near_click_control_center = true;
              };

              launcher = {
                app_grid = true;
                categories = true;
                show_icons = true;
                sort_by_usage = true;
                session_search = true;
              };

              screen_corners = {
                enabled = true;
                size = 24;
              };

              screenshot = {
                save_to_file = true;
                copy_to_clipboard = true;
                freeze_screen = true;
                directory = "~/Pictures/Screenshots";
              };
            };

            theme = {
              mode = "dark";
              source = "wallpaper";
              wallpaper_scheme = "m3-tonal-spot";
              templates = {
                builtin_ids = [
                  "cava"
                  "gtk3"
                  "gtk4"
                  "kcolorscheme"
                  "qt"
                  "niri"
                  "foot"
                  "btop"
                  "starship"
                ];
              };
            };

            wallpaper = {
              enabled = true;
              directory = "~/Pictures/Wallpapers";
              fill_mode = "crop";
              transition = [
                "fade"
                "disc"
                "stripes"
                "wipe"
                "zoom"
                "honeycomb"
              ];
              transition_duration = 1500;
              edge_smoothness = 0.3;
              transition_on_startup = true;
            };

            weather = {
              enabled = true;
              unit = "metric";
              effects = true;
            };

            location = {
              auto_locate = false;
              address = "Toronto, ON, Canada";
              latitude = 43.6532;
              longitude = -79.3832;
            };

            nightlight = {
              enabled = true;
              force = false;
              temperature_day = 4300;
              temperature_night = 3800;
            };

            notification = {
              enable_daemon = true;
              layer = "overlay";
              background_opacity = 0.9;
              offset_x = 16;
              offset_y = 12;
            };

            osd = {
              orientation = "vertical";
              position_vertical = "center_right";
              position = "top_right";
              background_opacity = 0.9;
              offset_x = 16;
              offset_y = 12;
            };

            audio = {
              enable_overdrive = false;
            };

            brightness = {
              enable_ddcutil = false;
            };

            lockscreen = {
              enabled = true;
              blurred_desktop = true;
              blur_intensity = 0.8;
              tint_intensity = 0.4;
            };

            control_center = {
              shortcuts = [
                { type = "wifi"; }
                { type = "bluetooth"; }
                { type = "caffeine"; }
                { type = "power_profile"; }
                { type = "nightlight"; }
                { type = "wallpaper"; }
              ];
            };

            # Floating glass top bar with launcher button
            bar = {
              main = {
                position = "top";
                thickness = 32;
                background_opacity = 0.6;
                margin_edge = 0;
                margin_ends = 0;
                padding = 10;
                widget_spacing = 10;
                radius = 10;
                shadow = true;
                auto_hide = false;
                reserve_space = true;
                font_weight = 600;

                start = [
                  "launcher"
                  "gap"
                  "control-center"
                  "gap"
                  "clock"
                  "gap"
                  "weather"
                  "gap"
                  "gap"
                  "active_window"
                ];
                center = [ "workspaces" ];
                end = [
                  "media"
                  "media_viz"
                  "gap"
                  "cpu"
                  "ram"
                  "gap"
                  "network"
                  "bluetooth"
                  "volume"
                  "microphone"
                  "brightness"
                  "gap"
                  "gap"
                  "tray"
                  "clipboard"
                  "notifications"
                  "gap"
                  "battery"
                  "caffeine"
                  "session"
                ];
              };
            };

            # Widgets
            widget = {
              launcher = {
                glyph = "apps";
              };

              clock = {
                format = "{:%H:%M:%S}  󰃭 {:%a %d %b}";
                tooltip_format = "{:%A, %d %B %Y — %I:%M:%S %p}";
                color = "primary";
              };

              weather = {
                show_condition = true;
                show_temperature = true;
                color = "tertiary";
              };

              gap = {
                type = "spacer";
                length = 16;
              };

              media = {
                min_length = 80;
                max_length = 150;
                art_size = 24;
                title_scroll = "always";
                hide_when_no_media = true;
              };

              media_viz = {
                type = "audio_visualizer";
                width = 60;
                bands = 20;
                mirrored = true;
                centered = true;
                show_when_idle = false;
                color_1 = "primary";
                color_2 = "tertiary";
              };

              active_window = {
                display = "icon_and_text";
                max_length = 300;
                title_scroll = "on_hover";
                color = "secondary";
              };

              workspaces = {
                display = "name";
                max_label_chars = 10;
                labels_only_when_occupied = true;
                focused_color = "primary";
                occupied_color = "tertiary";
                empty_color = "outline";
                pill_scale = 1.2;
                active_pill_size = 2.4;
                hide_when_empty = true;
              };

              tray = {
                drawer = true;
              };

              cpu = {
                type = "sysmon";
                stat = "cpu_usage";
                display = "gauge";
                show_label = false;
                highlight_color = "error";
              };

              ram = {
                type = "sysmon";
                stat = "ram_pct";
                display = "gauge";
                show_label = false;
                highlight_color = "error";
              };

              network = {
                show_label = true;
              };

              microphone = {
                type = "volume";
                device = "input";
                mute_color = "error";
              };

              battery = {
                display_mode = "graphic";
                show_label = true;
                warning_color = "error";
              };

              notifications = {
                hide_when_no_unread = false;
              };

              session = {
                icon_color = "error";
              };
            };
          };
        };
      }
    )
  ];
}
