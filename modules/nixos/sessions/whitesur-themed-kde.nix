{
  pkgs,
  ...
}:
{
  imports = [
    ./plasma-session-base.nix
    ./whitesur-theme.nix
  ];

  services.displayManager = {
    defaultSession = "plasma";
  };

  environment.systemPackages = with pkgs; [
    kdePackages.bluedevil
    thunderbird
    libappindicator-gtk3
  ];

  environment.variables = {
    ICON_THEME = "WhiteSur";
    GTK_THEME = "WhiteSur-Dark";
    GTK_ICON_THEME = "WhiteSur";
    GTK_CURSOR_THEME = "capitaine-cursors";
  };

}
