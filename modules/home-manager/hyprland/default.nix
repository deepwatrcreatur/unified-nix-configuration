{
  config,
  pkgs,
  lib,
  ...
}:

{
  assertions =
    let
      extra = config.wayland.windowManager.hyprland.extraConfig or "";
      lines = lib.strings.splitString "\n" extra;

      deprecatedKeys = [
        "drop_shadow"
        "shadow_range"
        "shadow_render_power"
        "col.shadow"
        "new_is_master"
      ];
      foundDeprecatedKeys = builtins.filter (k: lib.strings.hasInfix k extra) deprecatedKeys;

      # Basic syntax sanity for binds: catches the common "bind = $mainMod, exec, ..." mistake.
      dispatcherLike = [
        "exec"
        "execr"
        "workspace"
        "movetoworkspace"
        "movetoworkspacesilent"
        "togglefloating"
        "fullscreen"
        "killactive"
        "exit"
        "movefocus"
        "movewindow"
        "resizewindow"
        "pin"
        "togglespecialworkspace"
      ];

      isBindLine =
        line:
        let
          t = lib.strings.trim line;
        in
        lib.strings.hasPrefix "bind" t;

      parseCsv = s: builtins.map lib.strings.trim (lib.strings.splitString "," s);

      bindIssues =
        let
          bindLines = builtins.filter isBindLine lines;
          issuesForLine =
            line:
            let
              t = lib.strings.trim line;
              # Expect: "MODS, KEY, DISPATCHER, ..."; we don't validate mods.
              afterEq =
                if lib.strings.hasInfix "=" t then
                  lib.strings.trim (lib.lists.last (lib.strings.splitString "=" t))
                else
                  "";
              parts = parseCsv afterEq;
              key = if builtins.length parts > 1 then builtins.elemAt parts 1 else "";
            in
            if afterEq == "" then
              [ "bind missing '=': ${t}" ]
            else if builtins.length parts < 3 then
              [ "bind needs at least 3 fields (mods,key,dispatcher): ${t}" ]
            else if key == "" then
              [ "bind has empty key field: ${t}" ]
            else if builtins.elem key dispatcherLike then
              [ "bind key looks like a dispatcher (missing key?): ${t}" ]
            else
              [ ];
        in
        lib.lists.flatten (builtins.map issuesForLine bindLines);

    in
    [
      {
        assertion = foundDeprecatedKeys == [ ];
        message = "Hyprland config contains deprecated/removed keys: ${builtins.concatStringsSep ", " foundDeprecatedKeys}";
      }
      {
        assertion = bindIssues == [ ];
        message = "Hyprland config bind preflight failed:\n${builtins.concatStringsSep "\n" bindIssues}";
      }
    ];

  home.packages = with pkgs; [
    nwg-drawer # COSMIC-like app grid drawer
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Monitor configuration - dual monitors at native resolutions
      # Use 'preferred' for native resolution, explicit positioning
      monitor=,preferred,auto,1

      # Cursor theme - Capitaine (conventional pointer cursor)
      exec-once = hyprctl setcursor capitaine-cursors 24
      env = XCURSOR_THEME,capitaine-cursors
      env = XCURSOR_SIZE,24

      # Transparent dock + panel
      exec-once = waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &
      exec-once = sleep 1 && waybar -c ~/.config/waybar/dock-config.json -s ~/.config/waybar/dock-style.css &

      # Set programs that you use
      $terminal = wezterm
      $fileManager = thunar
      $menu = nwg-drawer

      # Environment variables
      env = QT_QPA_PLATFORMTHEME,qt5ct

      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =

          follow_mouse = 1

          touchpad {
              natural_scroll = yes
          }

          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
      }

      general {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          gaps_in = 5
          gaps_out = 20
          border_size = 3
          col.active_border = rgba(88c0d0ee) rgba(5e81acee) 45deg
          col.inactive_border = rgba(3b4252aa)

          layout = dwindle

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false
      }

      decoration {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          rounding = 10

          blur {
              enabled = true
              size = 3
              passes = 1
          }

          shadow {
              enabled = true
              range = 4
              render_power = 3
              color = rgba(1a1a1aee)
          }
      }

      animations {
          enabled = yes

          # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

          bezier = myBezier, 0.05, 0.9, 0.1, 1.05

          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      dwindle {
          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = yes # you probably want this
      }

      master {
          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          new_status = master
      }


      misc {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more
          force_default_wallpaper = 0 # Set to 0 to disable the anime mascot wallpapers
          disable_hyprland_logo = true
      }

      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrule = suppressevent maximize, class:.* # Ignore maximize requests.

      # See https://wiki.hyprland.org/Configuring/Keywords/#executing-for-more
      $mainMod = SUPER

      # Application launches
      bind = $mainMod, Q, exec, $terminal
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, SPACE, exec, $menu

      # Window management
      bind = $mainMod, C, killactive,
      bind = $mainMod, W, killactive,
      bind = ALT, F4, killactive,
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, F, fullscreen, 0
      bind = $mainMod, M, exit,

      # Volume controls (like COSMIC)
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Alternative volume controls (if media keys don't work)
      bind = $mainMod, equal, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = $mainMod, minus, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

      # Settings/Control center
      bind = $mainMod, I, exec, pavucontrol
      bind = $mainMod SHIFT, S, exec, gnome-control-center

      # Failsafes: usable even if $mainMod binds change
      bind = CTRL ALT, T, exec, $terminal
      bind = CTRL ALT, BackSpace, exit,
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle

      bind = $mainMod, O, exec, wofi --show run

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      # Example special workspace (scratchpad)
      bind = $mainMod SHIFT, S, movetoworkspacesilent, special
      bind = $mainMod, S, togglespecialworkspace,

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      # Per-screen workspace switching
      bind = $mainMod, right, focusmonitor, +1
      bind = $mainMod, left, focusmonitor, -1
    '';
  };

  xdg.configFile."waybar/config".text = builtins.readFile ./bar-config.json;
  xdg.configFile."waybar/style.css".text = builtins.readFile ./bar-style.css;
  xdg.configFile."waybar/dock-config.json".text = builtins.readFile ./dock-config.json;
  xdg.configFile."waybar/dock-style.css".text = builtins.readFile ./dock-style.css;

  services.hypridle = {
    enable = false;
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      # Set wallpaper on ALL monitors using wildcard
      wallpaper = let
        wallpaperPath = "${config.home.homeDirectory}/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg";
      in [
        ",${wallpaperPath}"  # Empty monitor name = apply to all monitors
      ];
      preload = [
        "${config.home.homeDirectory}/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg"
      ];
    };
  };

  programs.wofi = {
    enable = true;
    style = ''
      window {
          margin: 50px;
          background-color: rgba(255, 255, 255, 0.8);
          border-radius: 10px;
          border: 1px solid rgba(0, 0, 0, 0.1);
      }

      #input {
          margin: 5px;
          border: none;
          color: #2e3440;
          background-color: rgba(0, 0, 0, 0.1);
      }

      #inner-box {
          margin: 5px;
          border: none;
          background-color: transparent;
      }

      #outer-box {
          margin: 5px;
          border: none;
          background-color: transparent;
      }

      #scroll {
          margin: 0px;
          border: none;
      }

      #text {
          margin: 5px;
          border: none;
          color: #2e3440;
      }

      #entry:selected {
          background-color: rgba(0, 0, 0, 0.1);
      }
    '';
  };

  # nwg-drawer configuration for COSMIC-like app grid
  xdg.configFile."nwg-drawer/drawer.css".text = ''
    window {
      background-color: rgba(30, 30, 46, 0.95);
      color: #eceff4;
      font-family: 'Noto Sans', sans-serif;
    }

    #searchbox {
      background-color: rgba(255, 255, 255, 0.1);
      color: #eceff4;
      border: 1px solid rgba(255, 255, 255, 0.2);
      border-radius: 8px;
      padding: 8px;
      margin: 20px;
    }

    button {
      background-color: transparent;
      color: #eceff4;
      border: none;
      padding: 8px;
      margin: 4px;
      border-radius: 8px;
    }

    button:hover {
      background-color: rgba(255, 255, 255, 0.15);
    }

    button:focus {
      background-color: rgba(136, 192, 208, 0.3);
    }
  '';
}
