{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ===========================================
  # XFCE Home Manager Configuration
  # XFCE configuration via xfconf
  # Using UNSTABLE channel for latest opencode
  home.file.".config/xfce/xfce-perchannel-xml/xfwm4.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfwm4" version="1.0">
      <property name="general" type="empty">
        <!-- Window manager theme -->
        <property name="theme" type="string" value="WhiteSur-Dark"/>
      </property>
    </channel>
  '';
}
