# macOS-like Cinnamon Configuration

This configuration provides a complete macOS-like desktop experience using Cinnamon on NixOS.

## 🍎 Features

### Spotlight-like Application Launcher
- **Ulauncher**: macOS Spotlight equivalent
- **Activation**: `Ctrl+Space` (configurable)
- **Theme**: Dark mode with WhiteSur icons
- **Auto-hide**: Hides when focus is lost (macOS behavior)

### macOS-like Desktop Behavior
- **Auto-hide Panel**: Cinnamon panel acts like macOS dock
- **Single Workspace**: macOS-style workspace management
- **Window Controls**: Close/minimize/maximize on left side
- **Focus Behavior**: Click-to-focus (macOS default)
- **Hot Corners**: Mission Control-like functionality

### Audio Controls
- **Function Keys**: Volume up/down/mute
- **Smooth Transitions**: Flat volumes for macOS-like volume changes
- **Audio GUI**: pavucontrol for macOS-like preferences

### Keyboard Shortcuts
| Action | macOS Equivalent | Cinnamon Shortcut |
|--------|------------------|------------------|
| Application Switcher | `Cmd+Tab` | `Super+Tab` |
| Mission Control | `Ctrl+Up` | `Super+Control+Arrow` |
| Close Window | `Cmd+Q` | `Super+Q` |
| Minimize | `Cmd+M` | `Super+M` |
| Maximize | `Ctrl+Up` | `Super+Up` |
| Show Desktop | `F11` | `Super+D` |
| Screenshot | `Cmd+Shift+3` | `Print` |
| Area Screenshot | `Cmd+Shift+4` | `Alt+Print` |

### Visual Effects
- **Compositor**: Picom with blur and transparency
- **Theme**: WhiteSur-dark GTK theme with macOS-like icons
- **Cursors**: White-cursor theme matching macOS
- **Shadows & Fading**: Smooth window animations

## 🚀 Installation

Add this module to your NixOS configuration:

```nix
{
  imports = [
    "${./modules/nixos/sessions}/cinnamon.nix"
  ];
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## 🔧 Manual Configuration

After installation, you can manually run the setup script:

```bash
macos-cinnamon-setup
```

This will:
- Configure Ulauncher for macOS-like behavior
- Set up audio controls
- Configure Cinnamon desktop behavior
- Apply macOS-like keyboard shortcuts

## 📁 Configuration Files

The configuration consists of:

- **`cinnamon.nix`**: Main NixOS module
- **`whitesur-theme.nix`**: WhiteSur theme configuration
- **`cinnamon/*.sh`**: Configuration scripts for different components

### Configuration Scripts

- `ulauncher-config.sh`: Ulauncher setup for Spotlight-like behavior
- `audio-setup.sh`: PulseAudio configuration for macOS-like volume control
- `cinnamon-config.sh`: Cinnamon desktop behavior configuration
- `keybinds-config.sh`: macOS-like keyboard shortcuts
- `setup-cinnamon-macos.sh`: Master setup script that runs all configurations

## 🎨 Customization

### Theme Variants
- **Dark**: `WhiteSur-dark` (default)
- **Light**: `WhiteSur` (light mode)

### Custom Shortcuts
Edit `keybinds-config.sh` to modify keyboard shortcuts.

### Dock Behavior
Edit `cinnamon-config.sh` to adjust:
- Auto-hide delays
- Panel size
- Workspace count

## 🔍 Troubleshooting

### Ulauncher not starting
```bash
# Check service status
systemctl --user status ulauncher
# Restart manually
systemctl --user restart ulauncher
```

### Keyboard shortcuts not working
```bash
# Re-run keybind configuration
~/.config/cinnamon/keybinds-config.sh
```

### Audio controls not working
```bash
# Re-run audio configuration
~/.config/cinnamon/audio-setup.sh
```

## 📱 Additional Tools

The configuration includes optional macOS-like tools:
- **Flameshot**: Screenshot tool (`flameshot gui`)
- **CopyQ**: Clipboard manager with history
- **Deskflow**: Mouse/keyboard sharing across machines

## 🎯 System Requirements

- NixOS with Cinnamon desktop
- Audio system (PulseAudio or Pipewire)
- X11 server (required for Cinnamon)

---

**Note**: This configuration is designed to provide a familiar macOS experience while maintaining the flexibility and power of NixOS and Cinnamon.