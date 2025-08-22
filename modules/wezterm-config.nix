# modules/wezterm-config.nix
{
  imports = [ ./wezterm.nix ];
  programs.wezterm = {
    enable = true;
    font = {
      name = "JetBrains Mono";
      size = 16.0;
    };
    colorScheme = "Catppuccin Mocha";
    window = {
      opacity = 1.0;
      decorations = "RESIZE";
      adjustSizeWhenChangingFont = false;
    };
    tabs.enable = false;
    scrollbackLines = 5000;
    macos = {
      nativeFullscreen = true;
      windowBackgroundBlur = 30;
    };
    linux.enableWayland = true;
    keyBindings = [
      { key = "q"; mods = "CTRL"; action = "ToggleFullScreen"; }
      { key = "'"; mods = "CTRL"; action = "ClearScrollback 'ScrollbackAndViewport'"; }
    ];
    mouseBindings = [
      {
        event = "Up = { streak = 1, button = 'Left' }";
        mods = "CTRL";
        action = "OpenLinkAtMouseCursor";
      }
    ];
    extraConfig = ''
      -- Any additional custom Lua configuration
    '';
  };
}
