# modules/home-manager/common/nightscout-display.nix
# Multi-modal display interface for Nightscout continuous glucose telemetry:
# - Modality A: 'tui' (Lightweight Braille scatter plot terminal monitor via nightscout-tui)
# - Modality B: 'kiosk' (Fullscreen web single-page app via cage Wayland compositor + chromium)
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:

with lib;

let
  cfg = config.services.nightscout-display;

  # Determine nightscout-tui package from flake input, pkgs, or minimal script fallback
  nightscoutTuiPkg =
    if inputs ? nightscout-tui && inputs.nightscout-tui ? packages.${pkgs.system}.default then
      inputs.nightscout-tui.packages.${pkgs.system}.default
    else if pkgs ? nightscout-tui then
      pkgs.nightscout-tui
    else
      pkgs.writeShellScriptBin "nightscout-tui" ''
        exec ${pkgs.python3}/bin/python3 -c "print('Please provide nightscout-tui input or package'); exit 1"
      '';

  kioskScript = pkgs.writeShellScriptBin "nightscout-kiosk" ''
    set -euo pipefail

    TOKEN_PARAM=""
    if [ -n "${if cfg.token != null then cfg.token else ""}" ]; then
      TOKEN_PARAM="?token=${if cfg.token != null then cfg.token else ""}"
    elif [ -n "${if cfg.tokenFile != null then cfg.tokenFile else ""}" ] && [ -f "${if cfg.tokenFile != null then cfg.tokenFile else ""}" ]; then
      TOKEN_PARAM="?token=$(cat "${if cfg.tokenFile != null then cfg.tokenFile else ""}")"
    fi

    TARGET_URL="${cfg.url}''${TOKEN_PARAM}"

    echo "Starting Nightscout Wayland Kiosk display on Cage..."
    exec ${cfg.cagePackage}/bin/cage -- ${cfg.browserPackage}/bin/chromium \
      --kiosk \
      --noerrdialogs \
      --disable-infobars \
      --no-first-run \
      --check-for-update-interval=31536000 \
      --ozone-platform=wayland \
      "$TARGET_URL"
  '';

  tuiExecArgs = [
    "--url"
    cfg.url
    "--units"
    cfg.units
    "--low"
    (toString cfg.targetLow)
    "--high"
    (toString cfg.targetHigh)
    "--count"
    (toString cfg.count)
    "--refresh"
    (toString cfg.refreshInterval)
  ] ++ lib.optional (cfg.token != null) "--token ${cfg.token}"
    ++ lib.optional (cfg.tokenFile != null) "--token-file ${cfg.tokenFile}";
in
{
  options.services.nightscout-display = {
    enable = mkEnableOption "Nightscout display interface (TUI or Web Kiosk)";

    mode = mkOption {
      type = types.enum [ "tui" "kiosk" ];
      default = "tui";
      description = ''
        Display mode:
        - `tui`: Ultra-lightweight Unicode Braille scatter plot via nightscout-tui (<25MB RAM, 0% CPU idle).
        - `kiosk`: Wayland standalone web kiosk via Cage compositor + Chromium (~200MB RAM, full SPA & alarms).
      '';
    };

    url = mkOption {
      type = types.str;
      default = "https://nightscout.deepwatercreature.com";
      description = "Nightscout base URL.";
    };

    token = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Nightscout authentication Subject Token (plaintext).";
    };

    tokenFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing Nightscout authentication token.";
    };

    units = mkOption {
      type = types.enum [ "mg/dl" "mmol/l" ];
      default = "mg/dl";
      description = "Glucose display units: mg/dl or mmol/l.";
    };

    targetLow = mkOption {
      type = types.int;
      default = 70;
      description = "Lower target threshold in mg/dL.";
    };

    targetHigh = mkOption {
      type = types.int;
      default = 180;
      description = "Upper target threshold in mg/dL.";
    };

    refreshInterval = mkOption {
      type = types.int;
      default = 60;
      description = "TUI refresh interval in seconds.";
    };

    count = mkOption {
      type = types.int;
      default = 48;
      description = "Number of historical 5m readings to plot (~4 hours).";
    };

    tty = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Virtual console device to attach standard I/O to (e.g., /dev/tty1).";
    };

    tuiPackage = mkOption {
      type = types.package;
      default = nightscoutTuiPkg;
      description = "Package providing the nightscout-tui binary.";
    };

    cagePackage = mkOption {
      type = types.package;
      default = pkgs.cage;
      description = "Cage Wayland compositor package.";
    };

    browserPackage = mkOption {
      type = types.package;
      default = pkgs.chromium;
      description = "Browser package for kiosk mode.";
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      if cfg.mode == "tui" then
        [ cfg.tuiPackage ]
      else
        [ cfg.cagePackage cfg.browserPackage kioskScript ];

    systemd.user.services.nightscout-display = {
      Unit = {
        Description = "Nightscout Display (${toUpper cfg.mode} mode)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart =
          if cfg.mode == "tui" then
            "${cfg.tuiPackage}/bin/nightscout-tui ${escapeShellArgs tuiExecArgs}"
          else
            "${kioskScript}/bin/nightscout-kiosk";
        Restart = "always";
        RestartSec = 10;
      } // optionalAttrs (cfg.tty != null) {
        StandardInput = "tty";
        StandardOutput = "tty";
        TTYPath = cfg.tty;
        TTYReset = true;
        TTYVHangup = true;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
