{ config, pkgs, lib, ... }:

{
  # ===========================================
  # LXDE Home Manager Configuration
  # ===========================================
  # macOS-like theming for LXDE desktop environment
  # LXDE uses a mix of configuration files and doesn't use dconf

  # ===========================================
  # GTK Theme Configuration
  # ===========================================
  gtk = lib.mkDefault {
    enable = true;

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };

    cursorTheme = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };
  };

  # ===========================================
  # Openbox Configuration (LXDE's window manager)
  # ===========================================
  home.file.".config/openbox/lxde-rc.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
      <theme>
        <name>WhiteSur-Dark</name>
        <titleLayout>CMN</titleLayout> <!-- Close, Minimize, mAximize on left like macOS -->
        <keepBorder>yes</keepBorder>
        <animateIconify>yes</animateIconify>
        <font place="ActiveWindow">
          <name>Noto Sans</name>
          <size>11</size>
          <weight>Bold</weight>
          <slant>Normal</slant>
        </font>
        <font place="InactiveWindow">
          <name>Noto Sans</name>
          <size>11</size>
          <weight>Normal</weight>
          <slant>Normal</slant>
        </font>
      </theme>
      <desktops>
        <number>1</number> <!-- Single workspace like macOS -->
        <firstdesk>1</firstdesk>
        <names>
          <name>Main</name>
        </names>
        <popupTime>0</popupTime>
      </desktops>
      <focus>
        <focusNew>yes</focusNew>
        <followMouse>no</followMouse>
        <focusLast>yes</focusLast>
        <underMouse>no</underMouse>
        <focusDelay>0</focusDelay>
        <raiseOnFocus>no</raiseOnFocus>
      </focus>
      <placement>
        <policy>Smart</policy>
        <center>yes</center>
        <monitor>Primary</monitor>
        <primaryMonitor>1</primaryMonitor>
      </placement>
    </openbox_config>
  '';

  # ===========================================
  # LXDE Panel Configuration
  # ===========================================
  # Note: LXDE panel configuration is in ~/.config/lxpanel/
  # This is complex and best done manually through the GUI

  # ===========================================
  # GTK Settings File
  # ===========================================
  home.file.".gtkrc-2.0".text = ''
    gtk-theme-name = "WhiteSur-Dark"
    gtk-icon-theme-name = "WhiteSur"
    gtk-font-name = "Noto Sans 11"
    gtk-cursor-theme-name = "capitaine-cursors"
    gtk-cursor-theme-size = 24
  '';

  # ===========================================
  # LXDE-specific packages
  # ===========================================
  home.packages = with pkgs; [
    # Additional LXDE tools if needed
    lxappearance  # GUI theme configurator
  ];
}
