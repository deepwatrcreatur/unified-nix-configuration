# den/aspects/desktop-niri-specialisation.nix
# Boot-menu trial of Niri + Noctalia alongside the host's default desktop.
# Reuses the workstation-niri and desktop-noctalia aspects, then overrides what
# conflicts with desktop-cosmic and tones effects down for weak integrated GPUs.
{
  primaryUser ? "deepwatrcreatur",
  ...
}@context:
{
  lib,
  pkgs,
  ...
}:
let
  # Same DRM wait as modules/nixos/sessions/cosmic.nix: greetd can start the
  # session before connectors appear, which leaves a black screen.
  niriSessionCommand = pkgs.writeShellScript "niri-session-greetd" ''
    set -eu

    for _ in $(seq 1 50); do
      if ls /sys/class/drm/card*-*/status >/dev/null 2>&1 \
        && grep -q "^connected$" /sys/class/drm/card*-*/status 2>/dev/null; then
        break
      fi
      sleep 0.2
    done

    exec ${pkgs.niri}/bin/niri-session
  '';

  greeterCommand = pkgs.writeShellScript "niri-greetd-greeter" ''
    set -eu
    exec ${pkgs.tuigreet}/bin/tuigreet \
      --time \
      --remember \
      --remember-user \
      --cmd ${lib.escapeShellArg (toString niriSessionCommand)}
  '';

  # Appends one CSV row per run, so the trial can be compared with the
  # cosmic-comp growth that prompted it.
  trialMetrics = pkgs.writeShellScript "niri-trial-metrics" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.procps ]}

    dir="$HOME/.local/state/niri-trial"
    file="$dir/metrics.csv"
    mkdir -p "$dir"
    [ -e "$file" ] || echo "time,niri_pid,niri_rss_kb,niri_cpu_ticks,noctalia_rss_kb,vram_used_b" > "$file"

    pid=$(pgrep -o -x niri || true)
    rss=""
    ticks=""
    if [ -n "$pid" ]; then
      rss=$(awk '/^VmRSS:/{print $2}' "/proc/$pid/status" 2>/dev/null || true)
      ticks=$(awk '{print $14 + $15}' "/proc/$pid/stat" 2>/dev/null || true)
    fi
    noctalia=$(ps -C noctalia -o rss= 2>/dev/null | awk '{s += $1} END {print s + 0}')
    vram=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -1 || true)

    echo "$(date -Iseconds),$pid,$rss,$ticks,$noctalia,$vram" >> "$file"
  '';
in
{
  specialisation.niri.configuration = {
    imports = [
      (import ./workstation-niri.nix context)
      (import ./desktop-noctalia.nix context)
    ];

    system.nixos.tags = [ "niri-noctalia" ];

    services.desktopManager.cosmic.enable = lib.mkForce false;

    # desktop-cosmic sets these with mkForce, so a stronger priority is required.
    services.greetd.settings = {
      initial_session.command = lib.mkOverride 40 (toString niriSessionCommand);
      default_session.command = lib.mkOverride 40 (toString greeterCommand);
    };

    xdg.portal.config.common.default = lib.mkForce [
      "gnome"
      "gtk"
    ];

    systemd.user.services.niri-trial-metrics = {
      description = "Record Niri trial resource usage";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = toString trialMetrics;
      };
    };

    systemd.user.timers.niri-trial-metrics = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
      };
    };

    home-manager.users.${primaryUser} = {
      programs.niri.settings = {
        outputs."HDMI-A-1".scale = 1.0;
        animations.slowdown = lib.mkForce 0.6;
        layout.shadow.enable = lib.mkForce false;

        binds = {
          "Mod+Return".action = lib.mkForce { spawn = [ "ghostty" ]; };
          "Mod+E".action = lib.mkForce { spawn = [ "ghostty" ]; };
        };
      };

      programs.noctalia.settings = {
        shell.panel.transparency_mode = lib.mkForce "solid";
        # Other templates write GTK, Qt and starship config outside Home Manager,
        # which would carry over when booting back into COSMIC.
        theme.templates.builtin_ids = lib.mkForce [ "niri" ];
      };
    };
  };
}
