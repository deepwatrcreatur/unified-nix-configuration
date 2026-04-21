{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../default.nix
    ./nh.nix
    ./distrobox.nix

    ../../../../modules/home-manager/agenix-user-secrets.nix
    ../../../../modules/home-manager/gnome-cosmic-style.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/git-ssh-signing.nix
    ../../../../modules/home-manager/ssh-agent.nix
    ../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/common/dmux.nix
  ];

  programs.dmux.enable = true;
  programs.qmd.enable = true;
  programs.repo-updater.enable = true;
  programs.beads.enable = true;
  # Upstream beads_rust currently fails Nix evaluation because its source does
  # not expose Cargo.lock. Keep bv installed, but skip the Rust CLI wrapper.
  programs.beads.enableBr = false;

  programs.rtk-hooks.integrations = {
    claude.enable = true;
    codex.enable = true;
    gemini.enable = true;
    opencode.enable = true;
  };

  services.agenix-user-secrets = {
    enable = true;
    secrets = {
      github-token = {
        source = ../../../../secrets-agenix/github-token.age;
        target = ".local/share/agenix-user-secrets/github-token";
        extraTargets = [ ".config/git/github-token" ];
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
      anthropic-api-key = {
        source = ../../../../secrets-agenix/anthropic-api-key.age;
        target = ".local/share/agenix-user-secrets/anthropic-api-key";
      };
      oauth-creds = {
        source = ../../../../secrets-agenix/oauth-creds.age;
        target = ".local/share/agenix-user-secrets/oauth-creds";
        extraTargets = [ ".gemini/oauth_creds.json" ];
      };
      bitwarden-data = {
        source = ../../../../secrets-agenix/bitwarden-data.age;
        target = ".local/share/agenix-user-secrets/bitwarden-data";
        extraTargets = [ ".config/Bitwarden CLI/data.json" ];
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
