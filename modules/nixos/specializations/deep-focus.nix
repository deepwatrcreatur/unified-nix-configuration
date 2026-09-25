# modules/nixos/specializations/deep-focus.nix
# Distraction-free deep focus bootloader specialization.
# Configures notification silence (Do-Not-Disturb on swaync, mako, GNOME, COSMIC),
# suppresses non-essential background services & update checks, and establishes
# a focused default workspace environment for concentrated development.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myModules.specializations.deepFocus;
  userName = config.host.primaryUser or "deepwatrcreatur";

  # Script to silence notifications across all supported notification systems
  dndScript = pkgs.writeShellScript "deep-focus-silence-notifications" ''
    # 1. swaync
    if command -v ${pkgs.swaynotificationcenter}/bin/swaync-client >/dev/null 2>&1; then
      ${pkgs.swaynotificationcenter}/bin/swaync-client -d -b || true
    fi

    # 2. mako
    if command -v ${pkgs.mako}/bin/makoctl >/dev/null 2>&1; then
      ${pkgs.mako}/bin/makoctl mode -a do-not-disturb || true
    fi

    # 3. GNOME dconf (live setting if in GNOME session)
    if command -v ${pkgs.glib}/bin/gsettings >/dev/null 2>&1; then
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.notifications show-banners false || true
    fi
  '';
in
{
  options.myModules.specializations.deepFocus = {
    enable = lib.mkEnableOption "deep-focus distraction-free specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation.deep-focus.configuration =
      { options, ... }:
      {
        system.nixos.tags = [ "deep-focus" ];

        # ---------------------------------------------------------
        # 1. 🔕 NOTIFICATION SILENCE (DO-NOT-DISTURB)
        # ---------------------------------------------------------
        # GNOME: disable notification pop-up banners system-wide
        programs.dconf.enable = lib.mkDefault true;
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/notifications" = {
                show-banners = false;
              };
            };
          }
        ];

        # Autostart DND trigger on login across Wayland / X11 sessions
        environment.etc."xdg/autostart/deep-focus-dnd.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Deep Focus Notification Silence
          Exec=${dndScript}
          Hidden=false
          NoDisplay=true
          X-GNOME-Autostart-enabled=true
        '';

        # ---------------------------------------------------------
        # 2. 🛑 SUPPRESS NON-ESSENTIAL BACKGROUND DAEMONS & UPDATES
        # ---------------------------------------------------------
        # Disable periodic cleanup/maintenance timers during deep focus
        systemd.timers = {
          nh-clean.enable = lib.mkForce false;
          podman-prune.enable = lib.mkForce false;
          snapper-cleanup.enable = lib.mkForce false;
          snapper-timeline.enable = lib.mkForce false;
        };

        # Disable background telemetry, geolocation, packagekit, and print spoolers
        services.geoclue2.enable = lib.mkForce false;
        services.packagekit.enable = lib.mkForce false;
        services.printing.enable = lib.mkForce false;

        # ---------------------------------------------------------
        # 3. 🖥️ FOCUSED WORKSPACE LAYOUT & LAUNCH ENVIRONMENT
        # ---------------------------------------------------------
        environment.variables = {
          FOCUS_MODE = "1";
          DO_NOT_DISTURB = "1";
        };

        # Per-user Home Manager workspace rules when Home Manager is present
        home-manager.users.${userName} =
          { options, ... }:
          {
            # GNOME DND via home-manager dconf
            dconf.settings."org/gnome/desktop/notifications" = {
              show-banners = lib.mkForce false;
            };

            # Niri workspace rules & focus configuration if Niri HM module is present
            programs = lib.optionalAttrs (options ? programs && options.programs ? niri) {
              niri.settings = {
                layout = {
                  focus-ring.width = lib.mkForce 2.0;
                };
              };
            };
          };
      };
  };
}
