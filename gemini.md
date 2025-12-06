## Agent Instructions
### Shell Environment
- **Default shell is Fish**: Use Fish shell syntax for all commands to ensure compatibility with coding agents
- **Avoid Nushell**: While Nushell is configured, Fish is set as default to prevent agent compatibility issues
### Multi-Host Configuration Awareness
- **Always check hostname first**: Start by running `hostname` to identify which host you're working on
- **Host-specific commands**: Use appropriate commands based on the host type:
  - **NixOS hosts** (homeserver, workstation, etc.): Use `sudo nixos-rebuild` commands, account for non-FHS compliance
  - **Darwin hosts** (macminim4): Use `darwin-rebuild` commands, respect macOS peculiarities
  - **LXC containers**: May require special handling for container-specific rebuilds
### Host Detection Examples
```bash
# Check which host you're on
hostname
# Then use appropriate rebuild commands:
# For NixOS: sudo nixos-rebuild switch --flake .#hostname
# For Darwin: darwin-rebuild switch --flake .#hostname
