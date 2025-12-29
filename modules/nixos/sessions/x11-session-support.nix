# Enable both Wayland and X11 sessions for GNOME
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Ensure X11 support is enabled alongside Wayland
  services.xserver = {
    enable = true;
    # Enable X11 session support for GNOME
    desktopManager.gnome.sessionPath = [ pkgs.gnome-session ];
  };

  # Configure GDM when GNOME is enabled
  # Keep Wayland disabled at GDM level to avoid AMD GPU issues in the display manager itself,
  # but create X11 session files so users can log in
  services.xserver.displayManager.gdm = lib.mkIf config.services.desktopManager.gnome.enable {
    enable = true;
    # Disable Wayland to avoid AMD GPU crashes
    wayland = false;

    # GDM configuration
    settings = {
      daemon = {
        # Disable Wayland entirely for stability
        WaylandEnable = false;
      };
      security = {
        # Disable automatic login to force session selection
        AutomaticLoginEnable = true;
      };
    };
  };

  # Ensure both session types are available in the greeter
  environment.systemPackages = with pkgs; [
    gnome-session # Required for GNOME on X11
  ];

  # Add /etc/xdg to GDM's XDG_DATA_DIRS so it can find our X11 session file
  systemd.services.display-manager.environment.XDG_DATA_DIRS = lib.mkForce "/etc/xdg:/run/current-system/sw/share";

  # Create X11 session file for GNOME since modern GNOME only provides Wayland sessions
  # This allows GDM to find a valid session when Wayland is disabled
  system.activationScripts.gnomeX11Session = ''
    mkdir -p /etc/xdg/xsessions
    cat > /etc/xdg/xsessions/gnome.desktop <<'EOF'
[Desktop Entry]
Name=GNOME
Name[ar]=جنوم
Name[as]=GNOME
Name[bg]=GNOME
Name[bn]=GNOME
Name[ca]=GNOME
Name[cs]=GNOME
Name[da]=GNOME
Name[de]=GNOME
Name[el]=GNOME
Name[en_GB]=GNOME
Name[eo]=GNOMO
Name[es]=GNOME
Name[et]=GNOME
Name[eu]=GNOME
Name[fa]=گنوم
Name[fi]=Gnome
Name[fr]=GNOME
Name[gl]=GNOME
Name[gu]=GNOME
Name[he]=GNOME
Name[hi]=GNOME
Name[hu]=GNOME
Name[id]=GNOME
Name[it]=GNOME
Name[ja]=GNOME
Name[kk]=GNOME
Name[ko]=그놈
Name[lt]=GNOME
Name[lv]=GNOME
Name[ml]=ഗ്നോം
Name[mr]=GNOME
Name[ms]=GNOME
Name[nb]=GNOME
Name[nl]=GNOME
Name[nn]=GNOME
Name[or]=ନୋମ
Name[pa]=ਗਨੋਮ
Name[pl]=GNOME
Name[pt]=GNOME
Name[pt_BR]=GNOME
Name[ro]=GNOME
Name[ru]=GNOME
Name[sk]=GNOME
Name[sl]=GNOME
Name[sr]=Гном
Name[sv]=GNOME
Name[ta]=GNOME
Name[te]=గ్నోమ్
Name[tr]=GNOME
Name[uk]=GNOME
Name[vi]=GNOME
Name[zh_CN]=GNOME
Name[zh_HK]=GNOME
Name[zh_TW]=GNOME
Comment=This session logs you into GNOME (X11)
Comment[es]=Esta sesión accede a GNOME
Comment[fr]=Cette session vous connecte dans GNOME
Exec=${pkgs.gnome-session}/bin/gnome-session
TryExec=${pkgs.gnome-session}/bin/gnome-session
Type=Application
DesktopNames=GNOME
X-GDM-SessionRegisters=true
EOF
  '';

  # XDG portals for both Wayland and X11 compatibility
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.common.default = "*";
  };
}
