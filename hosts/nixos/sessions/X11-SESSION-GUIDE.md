# X11 Session Compatibility Guide

This document provides guidance for establishing X11 compatibility for desktop sessions in NixOS.

## Common Issues and Solutions

### Symptom: Black Screen After Login

**Cause:** Conflicting session configurations between different modules.

**Solution:**
1. Use ONLY ONE session configuration approach:
   - Standard GNOME: `services.desktopManager.gnome.enable = true` with GDM
   - Custom X11: Only if you need a completely custom session file

2. Never mix:
   - `services.desktopManager.gnome.enable = true` AND custom `.desktop` file creation
   - Multiple display manager modules

### Symptom: Only Boot Messages Visible (No Login Screen)

**Cause:** GDM/X server not starting correctly.

**Check:**
```bash
# Check GDM status
systemctl status gdm

# Check Xorg logs
journalctl -b | grep -i xorg
journalctl -b | grep -i gdm
```

## Configuration Patterns

### Pattern 1: Standard GNOME with X11

```nix
services.xserver.enable = true;
services.desktopManager.gnome.enable = true;

services.displayManager.gdm = {
  enable = true;
  wayland = false;  # Force X11
};

services.displayManager.autoLogin = {
  enable = true;
  user = "username";
};

# Required packages
environment.systemPackages = with pkgs; [
  gnome-session
  gnome-shell
  xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk
];
```

### Pattern 2: GDM Force X11 for All Sessions

```nix
services.displayManager.gdm = {
  enable = true;
  wayland = false;
};
```

### Pattern 3: Custom X11 Session (Use Sparingly)

If you MUST create a custom session file, do it properly:

```nix
system.activationScripts.customX11Session = ''
  mkdir -p /etc/xdg/xsessions
  cat > /etc/xdg/xsessions/gnome-x11.desktop <<'EOF'
[Desktop Entry]
Name=GNOME X11
Comment=GNOME with X11
Exec=${pkgs.gnome-session}/bin/gnome-session
TryExec=${pkgs.gnome-session}/bin/gnome-session
Type=Application
DesktopNames=GNOME
EOF
'';
```

**Warning:** Custom session files may conflict with `services.desktopManager.gnome.enable`.

## Required Packages for X11 GNOME

Always include these packages:

| Package | Purpose |
|---------|---------|
| `gnome-session` | Session manager |
| `gnome-shell` | Desktop shell |
| `gnome-session-ctraced` | Debug/tracing support |
| `xdg-desktop-portal-gnome` | Desktop portal |
| `xdg-desktop-portal-gtk` | GTK portal fallback |

## Debugging Steps

1. **Check if X11 session is selected:**
   ```bash
   cat /etc/systemd/system/display-manager.service
   # Look for --wayland in the command line
   ```

2. **Verify session files exist:**
   ```bash
   ls -la /usr/share/xsessions/
   ls -la /etc/xdg/xsessions/
   ```

3. **Check GDM logs:**
   ```bash
   journalctl -u gdm -n 100
   ```

4. **Test X11 directly:**
   ```bash
   # Switch to TTY
   Ctrl+Alt+F2
   # Login and run
   startx
   ```

## Wayland vs X11 Considerations

### When to Use X11:
- Need X11-based tools (DeskFlow, input-leap)
- Running legacy X11 applications
- Specific GPU drivers that don't support Wayland

### When Wayland is Preferable:
- Newer GNOME version (47+)
- Better security model
- HiDPI scaling support
- Modern multi-monitor handling

## Anti-Patterns to Avoid

| Anti-Pattern | Problem |
|--------------|---------|
| Multiple display manager configs | They conflict and break startup |
| Custom session file + `gnome.enable = true` | Duplicate/conflicting session setup |
| Missing `gnome-session` package | Session manager not available |
| Wayland enabled when X11 required | Features that need X11 will fail |
| Auto-login without session type | May default to Wayland even when disabled |

## References

- [NixOS Manual: Desktop Environments](https://nixos.org/manual/nixos/stable/#sec-desktop-env)
- [GDM Configuration](https://discourse.nixos.org/t/gnome-with-x11/12345)
- [GNOME Session Management](https://help.gnome.org/admin/gdm/stable/configuration.en.html)
