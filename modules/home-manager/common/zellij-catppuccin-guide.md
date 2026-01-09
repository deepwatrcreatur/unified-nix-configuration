# Zellij Catppuccin with Ctrl-Alt Keybindings

This configuration replicates your tmux catppuccin aesthetic in zellij with Ctrl-Alt keybindings to avoid conflicts with TUI applications.

## Visual Features (matching tmux catppuccin)
- **Theme**: Catppuccin mocha colors
- **Tabs**: Rounded pill-shaped tabs like tmux `window_status_style "rounded"`
- **Status Bar**: Shows working directory like tmux `status-right`
- **Panes**: Rounded corners and catppuccin styling
- **Colors**: Exact catppuccin mocha palette

## Keybindings (Ctrl-Alt combinations)

### Tab Management
- `Ctrl+Alt+t` - Tab mode
- `Ctrl+Alt+c` - New tab
- `Ctrl+Alt+x` - Close tab
- `Ctrl+Alt+[/]` - Previous/Next tab
- `Ctrl+Alt+1-9` - Go to tab number

### Pane Management
- `Ctrl+Alt+p` - Pane mode
- `Ctrl+Alt+s` - Split pane down
- `Ctrl+Alt+v` - Split pane right
- `Ctrl+Alt+h/j/k/l` - Move focus (vim style)
- `Ctrl+Alt+Arrow keys` - Move focus

### Session Management
- `Ctrl+Alt+d` - Detach session
- `Ctrl+Alt+o` - Session mode
- `Ctrl+Alt+r` - Rename tab

### Modes
- `Ctrl+Alt+Space` - **Locked mode** (for TUI apps with Ctrl+T conflicts)
- `Ctrl+Alt=` - Resize mode
- `Ctrl+Alt+f` - Search mode
- `Ctrl+Alt+Enter` - Enter search mode

### Quit
- `Ctrl+Alt+q` - Quit zellij

## For TUI Applications with Ctrl+T Conflicts

Use **Locked Mode**:
1. Press `Ctrl+Alt+Space` to enter locked mode
2. All zellij keybindings are disabled
3. Use your TUI app normally (including Ctrl+T)
4. Press `Ctrl+Alt+Space` to return to normal mode

## Integration with Yazelix

The `yazelix` layout now includes:
- 📁 File Manager (yazi)
- 📝 Editor (helix)
- 💻 Terminal (shell)

All with catppuccin theming and descriptive labels.

## Migration from tmux

| tmux command | zellij equivalent |
|-------------|------------------|
| `prefix+c` | `Ctrl+Alt+c` |
| `prefix+x` | `Ctrl+Alt+x` |
| `prefix+n/p` | `Ctrl+Alt+[/]` |
| `prefix+hjkl` | `Ctrl+Alt+hjkl` |
| `prefix+d` | `Ctrl+Alt+d` |
| `prefix+&` | `Ctrl+Alt+x` |

## Enable in Your Configuration

Add to your home-manager configuration:

```nix
{
  programs.zellij-catppuccin = {
    enable = true;
    theme = "mocha";
    roundedTabs = true;
    showWorkingDirectory = true;
  };
  
  programs.yazelix = {
    enable = true;
    # Now includes catppuccin theming automatically
  };
}
```

Then rebuild: `home-manager switch --flake .#your-host`