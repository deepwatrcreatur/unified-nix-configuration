# 13 Nightscout Headless Laptop Display Interfaces

Status: `in-progress`
Suggested branch: `feat/nightscout-laptop-display`
Priority: `medium`

## Goal

Enable a headless Debian laptop (managed via Nix and Home Manager) to serve as a dedicated, low-power continuous glucose monitor (CGM) display, supporting two switchable interface modalities:

1. **Modality A (Lightweight Console TUI)**: A pure console / TTY dashboard running `nightscout-tui` (Unicode Braille scatter plot, delta vector, ANSI alerts, <25 MB RAM, 0% CPU idle, zero X11/Wayland overhead).
2. **Modality B (Minimal Wayland Web Kiosk)**: A standalone browser kiosk running `cage` (micro Wayland kiosk compositor) and Chromium or Firefox in fullscreen kiosk mode without a desktop environment (~200 MB RAM, full Nightscout web SPA features and alarms).

## Why

1. **Repurposed Hardware**: Repurposes an existing laptop running Debian without a graphical desktop environment into a reliable, always-on bedside or desk CGM telemetry monitor.
2. **Avoiding Bloat**: Running a full desktop environment (GNOME, KDE, XFCE) on a headless appliance consumes excessive memory, requires display managers (GDM/SDDM), and risks random background update popups or screen saver locks.
3. **Choice of Interface**:
   - **TUI Mode**: Extreme reliability, instant boot, high readability in low light, immune to browser memory leaks or WebGL/Chromium crashes.
   - **Web Kiosk Mode**: Full access to interactive Nightscout features (Careportal, Basal, IOB/COB tracking, interactive mouse hover, and web audio alarms).

## Architecture

```
                          Debian Headless Laptop
                        (Nix + Home Manager Config)
                                    │
               ┌────────────────────┴────────────────────┐
               ▼                                         ▼
      Modality A: TUI Monitor                  Modality B: Web Kiosk
   ┌───────────────────────────┐            ┌───────────────────────────┐
   │ Linux Virtual Console     │            │ Linux DRM / KMS Driver    │
   │ (/dev/tty1 or KMSCON)     │            │                           │
   │            │              │            │  Cage (Wayland Compositor)│
   │  nightscout-tui (Python)  │            │            │              │
   │  - Braille Scatter Plot   │            │  Chromium / Firefox       │
   │  - ANSI Color Thresholds  │            │  --kiosk mode             │
   │  - Memory: < 25 MB        │            │  Memory: ~200 MB          │
   └────────────┬──────────────┘            └────────────┬──────────────┘
                │                                        │
                └───────────────┬────────────────────────┘
                                ▼
         Nightscout API: https://nightscout.deepwatercreature.com
                        (?token=<laptop_token>)
```

## Scope

1. **Nightscout TUI Integration (`Modality A`)**:
   - Package reference: `github:deepwatrcreatur/nightscout-tui`.
   - Provide Home Manager service module:
     ```nix
     services.nightscout-tui = {
       enable = true;
       url = "https://nightscout.deepwatercreature.com";
       tokenFile = "/home/deepwatrcreatur/.secrets/nightscout-token";
       units = "mg/dl"; # or "mmol/l"
       systemd.enable = true;
       systemd.tty = "/dev/tty1";
     };
     ```
   - Support autostart via TTY login or systemd user service.
2. **Cage Web Kiosk Integration (`Modality B`)**:
   - Package reference: `pkgs.cage` and `pkgs.chromium` (or `pkgs.firefox`).
   - Create reusable Home Manager module `modules/home-manager/services/nightscout-kiosk.nix`:
     - Spawns `cage -- chromium --kiosk --noerrdialogs --disable-infobars --check-for-update-interval=31536000 --ozone-platform=wayland "https://nightscout.deepwatercreature.com/?token=<token>"`.
     - Sets up seatd / udev permissions for unprivileged DRM/KMS access (`video` and `render` groups).
     - Provides screen power management: configure DPMS timeouts or disable sleep via `wlopm` / `swayidle`.
3. **Host Profile Configuration**:
   - Create a clean host definition or profile in `modules/home-manager/` for the Debian laptop to import either `nightscout-tui` or `nightscout-kiosk`.
   - Document toggling between TUI and Kiosk mode.

## Validation

- **TUI Mode**:
  - `nightscout-tui --once` fetches and displays the current glucose level and Braille curve on the terminal.
  - Long-running service runs continuously on TTY without memory growth or flickering.
- **Kiosk Mode**:
  - `cage` boots directly into Chromium fullscreen displaying Nightscout.
  - Websockets (`socket.io`) establish live connection and update glucose readings without requiring manual page refresh.
  - Keyboard/touch interaction responds correctly for inspecting historical points.
