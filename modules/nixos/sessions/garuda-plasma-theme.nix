{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    beauty-line-icon-theme
    candy-icons
    capitaine-cursors
  ];

  environment.variables = {
    ICON_THEME = "BeautyLine";
  };
}
