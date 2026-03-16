{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  codingAgents = import ../../../../modules/home-manager/coding-agents-registry.nix {
    inherit pkgs inputs;
  };
in
{
  imports = [
    ../../default.nix
    ./nh.nix
    ./distrobox.nix

    ../../../../modules/home-manager
    ../../../../modules/home-manager/agenix-user-secrets.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/gpg-agent-cross-de.nix
    ../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/cosmic-settings.nix
    ../../../../modules/home-manager/common/dmux.nix
    inputs.agents-status-tray-home-manager.homeManagerModules.default
  ];

  programs.dmux.enable = true;
  services.agents-status-tray = {
    enable = true;
    agents = map (agent: {
      inherit (agent) id name command;
    }) codingAgents;
  };

  services.agenix-user-secrets = {
    enable = true;
    secrets = {
      github-token = {
        source = ../../../../secrets-agenix/github-token.age;
        target = ".local/share/agenix-user-secrets/github-token";
      };
      grok-api-key = {
        source = ../../../../secrets-agenix/grok-api-key.age;
        target = ".local/share/agenix-user-secrets/grok-api-key";
      };
      openrouter-api-key = {
        source = ../../../../secrets-agenix/openrouter-api-key.age;
        target = ".local/share/agenix-user-secrets/openrouter-api-key";
      };
      z-ai-api-key = {
        source = ../../../../secrets-agenix/z-ai-api-key.age;
        target = ".local/share/agenix-user-secrets/z-ai-api-key";
      };
      opencode-zen-api-key = {
        source = ../../../../secrets-agenix/opencode-zen-api-key.age;
        target = ".local/share/agenix-user-secrets/opencode-zen-api-key";
      };
      atuin-key-b64 = {
        source = ../../../../secrets-agenix/atuin-key-b64.age;
        target = ".local/share/agenix-user-secrets/atuin-key-b64";
      };
      oauth-creds = {
        source = ../../../../secrets-agenix/oauth-creds.age;
        target = ".local/share/agenix-user-secrets/oauth-creds";
      };
      bitwarden-data = {
        source = ../../../../secrets-agenix/bitwarden-data.age;
        target = ".local/share/agenix-user-secrets/bitwarden-data";
      };
      rclone-conf = {
        source = ../../../../secrets-agenix/rclone-conf.age;
        target = ".local/share/agenix-user-secrets/rclone-conf";
      };
      proxmox-api-token = {
        source = ../../../../secrets-agenix/proxmox-api-token.age;
        target = ".local/share/agenix-user-secrets/proxmox-api-token";
      };
    };
  };

  programs.distrobox.fedora.enable = true;

  home.packages = with pkgs; [
    inputs.nix-linuxbrew.packages.${pkgs.stdenv.hostPlatform.system}.brew-wrapper
    inputs.claude-statusline-flake.packages.${pkgs.stdenv.hostPlatform.system}.default # Your new claude-statusline package
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default         # Assuming codex-cli-nix is your claude-code package
    inputs.cosmic-applet-proxmoxbar.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.cosmic-applet-agents-status.packages.${pkgs.stdenv.hostPlatform.system}.default
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    megacmd
    obsidian
    obsidian-export
    rustdesk
    virt-viewer
    xorg.xhost # X11 host access control for DeskFlow
    wasistlos # WhatsApp desktop client (was previously whatsapp-for-linux)
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  # Set default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/jpeg" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/gif" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/webp" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
    };
    associations.added = {
      "image/png" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/jpeg" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/gif" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/webp" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
    };
  };

  xdg.desktopEntries.satty = {
    name = "Satty";
    genericName = "Screenshot Annotation";
    exec = "satty -f %f";
    terminal = false;
    categories = [ "Utility" "Graphics" ];
    mimeType = [ "image/png" "image/jpeg" ];
    icon = "satty";
    type = "Application";
    settings = {
      NoDisplay = "false";
    };
  };

  # Allow dconf activation so COSMIC/GNOME settings (theme/wallpaper) apply.
  # If you see activation-time dconf errors again, we can gate this behind a
  # `graphical-session.target` user service instead.

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # cosmic-applet-proxmoxbar config is generated at activation time
  # to inject the secret from agenix
  home.activation.cosmicAppletProxmoxbarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/cosmic-applet-proxmoxbar"
    SECRET_PATH="$HOME/.local/share/agenix-user-secrets/proxmox-api-token"
    if [ -f "$SECRET_PATH" ]; then
      API_TOKEN_SECRET=$(cat "$SECRET_PATH")
    else
      API_TOKEN_SECRET="secret-not-available"
    fi
    cat > "$HOME/.config/cosmic-applet-proxmoxbar/config.toml" <<EOF
base_url = "https://pve-tomahawk.deepwatercreature.com:8006"
api_token_id = "root@pam!cosmic-applet-proxmoxbar"
api_token_secret = "$API_TOKEN_SECRET"
verify_tls = false
poll_seconds = 30
EOF
  '';

  home.file.".local/share/applications/com.deepwatrcreatur.CosmicAppletProxmoxbar.desktop".text = ''
    [Desktop Entry]
    Name=ProxmoxBar
    Type=Application
    Exec=${inputs.cosmic-applet-proxmoxbar.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/cosmic-applet-proxmoxbar
    Terminal=false
    Categories=COSMIC;
    Keywords=COSMIC;Proxmox;Virtualization;
    Icon=network-workgroup-symbolic
    StartupNotify=true
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicShrinkable=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=10
  '';

  home.file.".local/share/applications/com.deepwatrcreatur.CosmicAppletAgentsStatus.desktop".text = ''
    [Desktop Entry]
    Name=Agents Status
    Type=Application
    Exec=${inputs.cosmic-applet-agents-status.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/cosmic-applet-agents-status
    Terminal=false
    Categories=COSMIC;
    Keywords=COSMIC;AI;Agents;Claude;Codex;
    Icon=utilities-terminal-symbolic
    StartupNotify=true
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicShrinkable=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=10
  '';

  home.file.".config/cosmic-applet-agents-status/config.toml".text = ''
    poll_seconds = 90
    claude_cache_ttl_seconds = 60
    openrouter_api_key_path = "${config.home.homeDirectory}/.local/share/agenix-user-secrets/openrouter-api-key"

    [[agents]]
    id = "claude"
    name = "Claude Code"
    command = "claude"

    [[agents]]
    id = "openrouter"
    name = "OpenRouter"
    command = "true"

    [[agents]]
    id = "codex"
    name = "Codex CLI"
    command = "codex"

    [[agents]]
    id = "gemini"
    name = "Gemini CLI"
    command = "gemini"

    [[agents]]
    id = "copilot"
    name = "GitHub Copilot"
    command = "copilot"

    [[agents]]
    id = "opencode"
    name = "OpenCode Zen"
    command = "opencode"

    [[agents]]
    id = "opencode-zai"
    name = "OpenCode Z.ai"
    command = "opencode-zai"
  '';

  # X11 display setup for DeskFlow
  systemd.user.services.xhost-deskflow = {
    Unit = {
      Description = "X11 host access for DeskFlow";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.xorg.xhost}/bin/xhost +local:";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Deskflow server service (disabled in favor of RustDesk)
  # Start manually with: systemctl --user start deskflow
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
      Wants = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
      Environment = [
        "DISPLAY=:0"
        "XAUTHORITY=${config.xdg.cacheHome}/.Xauthority"
      ];
    };
    Install = {
      # Disabled: WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
