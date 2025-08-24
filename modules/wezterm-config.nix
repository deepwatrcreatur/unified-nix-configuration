# modules/wezterm-config.nix - Your configuration file
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
      { key = "\\\""; mods = "CTRL"; action = "ClearScrollback 'ScrollbackAndViewport'"; }
    ];
    extraConfig = ''
      -- Default program: launch zellij with welcome layout
      config.default_prog = { '~/.nix-profile/bin/zellij', '-l', 'welcome' }
      
      -- Mouse bindings (manual for now)
      config.mouse_bindings = {
        {
          event = { Up = { streak = 1, button = 'Left' } },
          mods = 'CTRL',
          action = wezterm.action.OpenLinkAtMouseCursor,
        },
      }
    '';
  };
}
