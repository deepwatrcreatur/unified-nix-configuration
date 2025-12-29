{ config, pkgs, lib, ... }:

{
  # ===========================================
  # XFCE Home Manager Configuration
  # ===========================================
  # macOS-like theming for XFCE desktop environment
  # XFCE uses xfconf for settings, not dconf

  # XFCE configuration via xfconf (XML-based)
  # Note: XFCE doesn't use dconf, so we configure via home.file

  # ===========================================
  # GTK Theme Configuration
  # ===========================================
  gtk = {
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
  # XFCE-specific packages
  # ===========================================
  home.packages = with pkgs; [
    # XFCE plugins for macOS-like experience
    xfce.xfce4-whiskermenu-plugin  # Application menu
    xfce.xfce4-clipman-plugin      # Clipboard manager
  ];

  # ===========================================
  # XFCE Panel Configuration
  # ===========================================
  # Note: XFCE panel configuration is complex and typically done via GUI
  # The xfconf XML files can be managed but are fragile
  # Recommend manual configuration through XFCE Settings after first login

  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfwm4" version="1.0">
      <property name="general" type="empty">
        <!-- Window manager theme -->
        <property name="theme" type="string" value="WhiteSur-Dark"/>

        <!-- Window controls on left (macOS-style) -->
        <property name="button_layout" type="string" value="CmH|"/>

        <!-- Focus behavior -->
        <property name="click_to_focus" type="bool" value="true"/>
        <property name="focus_new" type="bool" value="true"/>

        <!-- Workspace settings -->
        <property name="workspace_count" type="int" value="1"/>

        <!-- Window placement -->
        <property name="placement_mode" type="string" value="center"/>

        <!-- Compositing for transparency -->
        <property name="use_compositing" type="bool" value="true"/>
        <property name="frame_opacity" type="int" value="90"/>
        <property name="inactive_opacity" type="int" value="90"/>
      </property>
    </channel>
  '';
}
