{ config, pkgs, ... }:

{
  # KDE Plasma Home Manager configuration
  programs.plasma = {
    enable = true;

    # Panel configuration - bottom panel with right alignment
    panels = [
      {
        location = "bottom";
        alignment = "right";
        height = 68;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.icontasks"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];

    # Additional plasma configuration can go here
    # workspace = {
    #   lookAndFeel = "org.kde.breezedark.desktop";
    # };
  };

  # KDE-specific applications
  home.packages = with pkgs; [
    # Add KDE-specific user applications here if needed
  ];
}
