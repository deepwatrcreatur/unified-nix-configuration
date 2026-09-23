# den/aspects/workstation-niri.nix
# Niri scrollable-tiling Wayland compositor aspect for workstation nodes.
# Fully aligned with niii-san/nixos-config (spring animations, shadows, opacity rules, Noctalia binds).
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # Essential Wayland utilities and terminals
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    libnotify
    pavucontrol
    brightnessctl
    playerctl
    foot
    alacritty
    xdg-utils
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

  # Greetd login manager: auto-login into Niri session
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

  # Home Manager Niri configuration
  home-manager.sharedModules = [
    inputs.niri.homeModules.config
    (
      { config, lib, pkgs, ... }:
      {
        programs.niri = {
          # Use official cached nixpkgs package for validation to avoid source git-fetch errors
          package = pkgs.niri;

          settings = {
            prefer-no-csd = true;

            input = {
              keyboard = {
                xkb.layout = "us";
                repeat-delay = 450;
                repeat-rate = 25;
              };
              touchpad = {
                accel-profile = "adaptive";
                accel-speed = 0.2;
                dwt = true;
                natural-scroll = true;
                tap = true;
                scroll-factor = 0.8;
              };
              focus-follows-mouse.enable = true;
            };

            hotkey-overlay = {
              hide-not-bound = true;
              skip-at-startup = true;
            };

            # ✦ Layer rules for Noctalia integration and screencast privacy
            layer-rules = [
              {
                # Mask notifications from screen recording / screenshare
                matches = [ { namespace = "^notification$"; } ];
                block-out-from = "screencast";
              }
              {
                # Noctalia wallpaper placed in backdrop layer
                matches = [ { namespace = "^noctalia-wallpaper.*"; } ];
                place-within-backdrop = true;
              }
              {
                # Noctalia blurred/tinted backdrop layer (overview blur)
                matches = [ { namespace = "^noctalia-backdrop.*"; } ];
                place-within-backdrop = true;
              }
            ];

            cursor = {
              hide-after-inactive-ms = 3000;
              hide-when-typing = true;
              size = 24;
            };

            environment = {
              XDG_CURRENT_DESKTOP = "niri";
              XDG_SESSION_DESKTOP = "niri";
            };

            gestures.hot-corners.enable = false;

            overview = {
              workspace-shadow.enable = false;
              zoom = 0.5;
            };

            # ✦ Layout with focus-ring gradients & window drop shadows
            layout = {
              background-color = "transparent";
              center-focused-column = "never";
              default-column-width.proportion = 0.5;
              gaps = 8;
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
                { proportion = 1.0; }
              ];
              focus-ring = {
                width = 1.5;
                active.gradient = {
                  angle = 210;
                  from = "#80c8ff";
                  relative-to = "workspace-view";
                  to = "#223366";
                };
                inactive.gradient = {
                  angle = 45;
                  from = "#505050";
                  relative-to = "workspace-view";
                  to = "#808080";
                };
              };
              shadow = {
                enable = true;
                softness = 30;
                spread = 5;
                offset.x = 0;
                offset.y = 8;
                color = "#00000060";
              };
            };

            # ✦ Silky smooth spring animations
            animations = {
              slowdown = 1.0;
              window-open.kind.spring = {
                damping-ratio = 0.8;
                stiffness = 1000;
                epsilon = 0.0001;
              };
              window-close.kind.easing = {
                duration-ms = 150;
                curve = "ease-out-cubic";
              };
              window-movement.kind.spring = {
                damping-ratio = 0.8;
                stiffness = 1000;
                epsilon = 0.0001;
              };
              workspace-switch.kind.easing = {
                duration-ms = 250;
                curve = "ease-out-expo";
              };
              overview-open-close.kind.easing = {
                duration-ms = 200;
                curve = "ease-out-expo";
              };
            };

            # ✦ Spawn at startup
            spawn-at-startup = [
              { command = [ "${noctaliaPkg}/bin/noctalia" ]; }
              { command = [ "${pkgs.xwayland-satellite}/bin/xwayland-satellite" ]; }
            ];

            # ✦ Per-application window rules (opacities, geometry corners, floaters)
            window-rules = [
              {
                matches = [ { app-id = "^pavucontrol$"; } ];
                open-floating = true;
                default-column-width.fixed = 800;
                default-window-height.fixed = 600;
              }
              {
                matches = [ { app-id = "^nm-connection-editor$"; } ];
                open-floating = true;
              }
              {
                matches = [ { app-id = "^org.gnome.Calculator$"; } ];
                open-floating = true;
              }
              {
                matches = [ { app-id = "^(imv|mpv)$"; } ];
                open-floating = true;
              }
              {
                matches = [ { title = "^Picture-in-Picture$"; } ];
                open-floating = true;
              }
              {
                matches = [ { title = "^(Open|Save) File.*$"; } ];
                open-floating = true;
              }
              {
                matches = [ { app-id = "^foot$"; } ];
                opacity = 0.92;
                draw-border-with-background = false;
                geometry-corner-radius = {
                  top-left = 10.0;
                  top-right = 10.0;
                  bottom-left = 10.0;
                  bottom-right = 10.0;
                };
                clip-to-geometry = true;
              }
              {
                matches = [ { app-id = "^(code|Code)$"; } ];
                opacity = 0.94;
                draw-border-with-background = false;
                geometry-corner-radius = {
                  top-left = 10.0;
                  top-right = 10.0;
                  bottom-left = 10.0;
                  bottom-right = 10.0;
                };
                clip-to-geometry = true;
              }
            ];

            # ✦ Comprehensive Keybindings
            binds = {
              # Terminal & Apps
              "Mod+Return".action.spawn = [ "foot" ];
              "Mod+E".action.spawn = [ "foot" ];
              "Mod+C".action.close-window = { };
              "Mod+F".action.maximize-column = { };
              "Mod+Shift+F".action.fullscreen-window = { };
              "Mod+T".action.toggle-window-floating = { };
              "Mod+O".action.toggle-overview = { };
              "Mod+R".action.switch-preset-column-width = { };
              "Mod+Shift+O".action.toggle-window-rule-opacity = { };

              # Noctalia Panel & IPC controls
              "Mod+Space".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "launcher"
              ];
              "Mod+Shift+Space".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "control-center"
              ];
              "Mod+W".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "wallpaper"
              ];
              "Mod+Shift+Comma".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "settings-toggle"
              ];
              "Mod+Escape".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "panel-toggle"
                "session"
              ];
              "Mod+Alt+L".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "session"
                "lock"
              ];
              "Mod+Shift+B".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "bar-toggle"
              ];
              "Mod+Shift+N".action.spawn = [
                "${noctaliaPkg}/bin/noctalia"
                "msg"
                "nightlight-toggle"
              ];

              # Media Controls
              "Mod+P".action.spawn = [ "playerctl" "play-pause" ];
              "Mod+Shift+P".action.spawn = [ "playerctl" "stop" ];
              "Mod+Comma".action.spawn = [ "playerctl" "previous" ];
              "Mod+Period".action.spawn = [ "playerctl" "next" ];

              # Column & Window Navigation
              "Mod+Left".action.focus-column-left = { };
              "Mod+Right".action.focus-column-right = { };
              "Mod+Up".action.focus-window-up = { };
              "Mod+Down".action.focus-window-down = { };
              "Mod+H".action.focus-column-left = { };
              "Mod+L".action.focus-column-right = { };
              "Mod+J".action.focus-window-down = { };
              "Mod+K".action.focus-window-up = { };

              # Column & Window Movement
              "Mod+Ctrl+Left".action.move-column-left = { };
              "Mod+Ctrl+Right".action.move-column-right = { };
              "Mod+Ctrl+Up".action.move-window-up = { };
              "Mod+Ctrl+Down".action.move-window-down = { };
              "Mod+Ctrl+H".action.move-column-left = { };
              "Mod+Ctrl+L".action.move-column-right = { };
              "Mod+Ctrl+J".action.move-window-down = { };
              "Mod+Ctrl+K".action.move-window-up = { };

              # Column Resizing
              "Mod+Shift+Left".action.set-column-width = "-10%";
              "Mod+Shift+Right".action.set-column-width = "+10%";
              "Mod+Shift+Up".action.set-window-height = "-10%";
              "Mod+Shift+Down".action.set-window-height = "+10%";
              "Mod+Shift+H".action.set-column-width = "-10%";
              "Mod+Shift+L".action.set-column-width = "+10%";
              "Mod+Shift+J".action.set-window-height = "-10%";
              "Mod+Shift+K".action.set-window-height = "+10%";

              # Workspaces
              "Mod+1".action.focus-workspace = 1;
              "Mod+2".action.focus-workspace = 2;
              "Mod+3".action.focus-workspace = 3;
              "Mod+4".action.focus-workspace = 4;
              "Mod+5".action.focus-workspace = 5;
              "Mod+6".action.focus-workspace = 6;
              "Mod+7".action.focus-workspace = 7;
              "Mod+8".action.focus-workspace = 8;
              "Mod+9".action.focus-workspace = 9;

              "Mod+Shift+1".action.move-column-to-workspace = 1;
              "Mod+Shift+2".action.move-column-to-workspace = 2;
              "Mod+Shift+3".action.move-column-to-workspace = 3;
              "Mod+Shift+4".action.move-column-to-workspace = 4;
              "Mod+Shift+5".action.move-column-to-workspace = 5;
              "Mod+Shift+6".action.move-column-to-workspace = 6;
              "Mod+Shift+7".action.move-column-to-workspace = 7;
              "Mod+Shift+8".action.move-column-to-workspace = 8;
              "Mod+Shift+9".action.move-column-to-workspace = 9;

              # Audio Hotkeys (XF86)
              "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];
              "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
              "XF86AudioMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
              "XF86AudioMicMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
              "XF86AudioPlay".action.spawn = [ "playerctl" "play-pause" ];
              "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
              "XF86AudioPrev".action.spawn = [ "playerctl" "previous" ];

              # Quit Session
              "Mod+Shift+M".action.quit = { };
            };
          };
        };
      }
    )
  ];
}
