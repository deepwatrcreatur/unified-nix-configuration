# Unified Nix Configuration Repository

This repository contains a unified Nix configuration for managing multiple systems, including NixOS, macOS, and Linux distributions. It uses Nix Flakes to ensure reproducible builds and deployments.

## Overview

The primary goal of this repository is to provide a single source of truth for system and user configurations across various machines. This includes:

-   System-level settings (e.g., networking, services)
-   User-specific configurations (e.g., shell environment, applications)
-   Secret management using `sops-nix`

## Technologies

-   **Nix:** A powerful package manager and system configuration tool.
-   **NixOS:** A Linux distribution built on top of the Nix package manager.
-   **home-manager:** A tool to manage user-level dotfiles and packages.
-   **Nix Flakes:** A new feature in Nix that improves reproducibility and composability.
-   **sops-nix:** A tool for managing secrets in Nix configurations.

## Directory Structure

-   `hosts/`: Contains the main configuration for each individual host. Each host has a dedicated directory with its specific NixOS or home-manager configuration.
  - Organized by platform: `nixos/`, `macminim4/` (darwin), `nixos-lxc/`, `infisical/`
  - Each host imports platform-specific modules automatically
-   `modules/`: Contains reusable Nix modules that are shared across different hosts. This includes common packages, system settings, and user configurations.
  - `common/`: Cross-platform modules imported by all hosts
  - `nix-darwin/`: macOS-specific modules (auto-imported only by Darwin hosts)
  - `nixos/`: Linux-specific modules (auto-imported only by NixOS hosts)
  - `home-manager/`: User environment modules
-   `users/`: Contains user-specific configurations, such as dotfiles, packages, and services.
  - Organized by username with host-specific overrides in `users/{username}/hosts/{hostname}/`
-   `secrets/`: Contains encrypted secret files managed by `sops`.
-   `outputs/`: Host output definitions using helper functions from flake.nix

## Getting Started

To apply the configuration for a specific host, you can use the following command from the root of the repository:

```bash
nixos-rebuild switch --flake .#<hostname>
```

Replace `<hostname>` with the name of the host you want to configure (e.g., `homeserver`, `workstation`).

```
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
```

### tmux Session Management for Remote Work
When working with remote hosts or running long-duration operations, use tmux to maintain persistent sessions:

#### Basic tmux Usage
```bash
# Create a named session for your work
ssh host "tmux new-session -d -s inference-test"

# Attach to session (interactive)
ssh -t host "tmux attach-session -t inference-test"

# Send commands to session without attaching
ssh host "tmux send-keys -t inference-test 'cd /path/to/work' Enter"
ssh host "tmux send-keys -t inference-test 'ollama serve' Enter"

# Check if session exists
ssh host "tmux list-sessions | grep inference-test"

# Kill session when done
ssh host "tmux kill-session -t inference-test"
```

#### Multiple Windows in tmux
```bash
# Create windows for different tasks
ssh host "tmux new-window -t inference-test -n 'server'"
ssh host "tmux new-window -t inference-test -n 'testing'"

# Send commands to specific windows
ssh host "tmux send-keys -t inference-test:server 'ollama serve' Enter"
ssh host "tmux send-keys -t inference-test:testing 'ollama list' Enter"

# List windows in session
ssh host "tmux list-windows -t inference-test"
```

#### Background Process Management
```bash
# Start background processes that persist across SSH disconnections
ssh host "tmux send-keys -t session-name 'nohup command > output.log 2>&1 &' Enter"

# Monitor background processes
ssh host "tmux send-keys -t session-name 'ps aux | grep process-name' Enter"

# Check process logs
ssh host "tmux send-keys -t session-name 'tail -f output.log' Enter"
```

#### Best Practices for Agents
- **Always use named sessions**: Makes it easier to reconnect and manage multiple concurrent tasks
- **Create task-specific sessions**: e.g., "inference-test", "build-debug", "service-monitor"
- **Use multiple windows**: Separate concerns like server processes, testing, and monitoring
- **Check session existence**: Before creating, verify if session already exists to avoid conflicts
- **Clean up**: Kill sessions when work is complete to avoid resource accumulation

### Remote Testing Workflow
For testing changes across hosts (especially build failures):
1. **Check hostname** on local machine first
2. **SSH to remote host** if needed:
   ```bash
   ssh user@hostname "rebuild command"
   ```
3. **Use tmux sessions** for maintaining persistent remote sessions (see tmux section above)
4. **Test platform-specific issues** by reproducing on relevant host type

### Worktrees
- Prefer `wt` (worktrunk) over `git worktree` when working in parallel.
- Typical flow: `wt switch -c feat/my-change`, then run agent work in that worktree.

### Git Workflow
Before pushing changes that affect remote hosts:
1. **Check local files exist** with `git status`
2. **Pull remote changes first** with `git pull` to avoid conflicts
3. **Test locally** (rebuild/switch) before committing when possible
4. **Split commits into logical parts**: keep commits narrowly scoped (e.g., "secrets refactor" separate from "GNOME tweaks")
5. **Commit WITHOUT GPG signing** (agents cannot reliably handle pinentry prompts):
   ```bash
   git commit --no-gpg-sign -m "feat: ..."
   ```
   If you need to disable signing for multiple commits in this repo:
   ```bash
   git config commit.gpgsign false
   ```
5. **Then push** with `git push`
```
