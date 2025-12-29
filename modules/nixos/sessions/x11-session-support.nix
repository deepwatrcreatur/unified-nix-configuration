# Simplified X11 session support for GNOME
# Based on garuda-themed-gnome.nix which is known to work
{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.xserver = {
    enable = true;
    desktopManager.gnome.sessionPath = [ pkgs.gnome-session ];
  };

  # GDM with X11 (Wayland disabled for DeskFlow compatibility)
  services.displayManager.gdm = {
    enable = true;
    wayland = false;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "deepwatrcreatur";
  };

  # Create X11 session file for GNOME
  system.activationScripts.gnomeX11Session = ''
    mkdir -p /etc/xdg/xsessions
    cat > /etc/xdg/xsessions/gnome.desktop <<'EOF'
[Desktop Entry]
Name=GNOME
Comment=This session logs you into GNOME (X11)
Exec=${pkgs.gnome-session}/bin/gnome-session
TryExec=${pkgs.gnome-session}/bin/gnome-session
Type=Application
DesktopNames=GNOME
X-GDM-SessionRegisters=true
EOF
  '';

  # Required packages for X11 GNOME
  environment.systemPackages = with pkgs; [
    gnome-session
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
  ];
}
