# den/aspects/desktop-niri-cosmic-fallback.nix
# Niri + Noctalia as the host's default desktop, with COSMIC kept as a
# boot-menu specialisation ("cosmic"). Reuses the workstation-niri and
# desktop-noctalia aspects and tones effects down for weak integrated GPUs.
#
# Priorities: the niri greetd commands below use mkOverride 60, which beats
# workstation-niri's plain values but loses to desktop-cosmic's mkForce (50),
# so the cosmic specialisation (which inherits this config) gets COSMIC's
# greetd session without further overrides.
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

  # Appends one CSV row per run, so niri can be compared with the
  # cosmic-comp growth that prompted the switch.
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
  imports = [
    (import ./workstation-niri.nix context)
    (import ./desktop-noctalia.nix context)
  ];

  # Beats workstation-niri's plain values; loses to desktop-cosmic's mkForce.
  services.greetd.settings = {
    initial_session.command = lib.mkOverride 60 (toString niriSessionCommand);
    default_session.command = lib.mkOverride 60 (toString greeterCommand);
  };

  specialisation.cosmic.configuration = {
    imports = [ (import ./desktop-cosmic.nix context) ];

    system.nixos.tags = [ "cosmic" ];

    programs.niri.enable = lib.mkForce false;

    # Both aspects set this list, and lists concatenate when merged.
    xdg.portal.config.common.default = lib.mkForce [
      "cosmic"
      "gtk"
    ];
  };

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
        # Vicinae alongside Noctalia's launcher (Mod+Space); same key as on
        # the Plasma hosts.
        "Alt+Space".action.spawn = [
          "${pkgs.vicinae}/bin/vicinae"
          "toggle"
        ];
      };
    };

    # `vicinae toggle` needs the server running.
    programs.vicinae = {
      enable = true;
      systemd.enable = true;
    };

    programs.noctalia.settings = {
      shell.panel.transparency_mode = lib.mkForce "solid";
      # Other templates write GTK, Qt and starship config outside Home Manager,
      # which would carry over when booting into the COSMIC specialisation.
      theme.templates.builtin_ids = lib.mkForce [ "niri" ];
    };
  };
}
