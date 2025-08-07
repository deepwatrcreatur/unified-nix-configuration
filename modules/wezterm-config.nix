{
  imports = [ ./wezterm.nix ];
  
  programs.wezterm = {
    enable = true;
    
    font = {
      name = "JetBrains Mono";
      size = 13.0;
    };
    
    # colorScheme = "Tokyo Night";
    
    window.opacity = 0.95;
    
    macos.nativeFullscreen = true;  # Only applied on macOS
    linux.enableWayland = true;    # Only applied on Linux
    
    keyBindings = [
      { key = "t"; mods = "CTRL|SHIFT"; action = "SpawnTab 'CurrentPaneDomain'"; }
    ];
    
    extraConfig = ''
      -- Any additional Lua configuration
      config.scrollback_lines = 5000
    '';
  };
}
