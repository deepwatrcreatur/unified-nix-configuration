{ config, lib, pkgs, ... }:

{
  # Install sshs package
  home.packages = with pkgs; [
    sshs  # TUI for SSH connections
  ];

  # Configure sshs
  home.file.".config/sshs/config.toml" = {
    text = ''
      # SSHS Configuration
      
      # Default settings
      [default]
      username = "${config.home.username}"
      port = 22
      
      # Key bindings (optional customization)
      [keybindings]
      quit = "q"
      connect = "Enter"
      edit = "e"
      delete = "d"
      add = "a"
      search = "/"
      
      # Theme configuration
      [theme]
      # Available themes: default, dark, light, solarized
      name = "dark"
      
      # Custom colors (optional)
      [theme.colors]
      # background = "#1e1e1e"
      # foreground = "#d4d4d4"
      # selected = "#264f78"
      # border = "#3c3c3c"
      
      # SSH connection profiles
      [[hosts]]
      name = "HomeServer"
      host = "10.10.11.69"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS LXC for services provided to homelab"
      tags = ["server"]
      
      [[hosts]]
      name = "cache and build server"
      host = "10.10.11.68"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS LXC for building nix packages"
      tags = ["server"]
      
      [[hosts]]
      name = "workstation"
      host = "10.10.11.73"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS workstation"
      tags = ["desktop"]
      
      [[hosts]]
      name = "opnsense"
      host = "10.10.10.1"
      username = "root"
      port = 22
      description = "Firewall"
      tags = ["homelab"]
      
      [[hosts]]
      name = "pvestrix"
      host = "10.10.11.57"
      username = "root"
      port = 22
      description = "Proxmox host"
      tags = ["homelab"]
      
      
      # Groups for organizing hosts
      [groups]
      homelab = ["pve-strix", "pve-tomahaw", "opnsense", "homeserver"]
      
      # Additional SSH options
      [ssh_options]
      # These will be passed to SSH
      StrictHostKeyChecking = "ask"
      UserKnownHostsFile = "~/.ssh/known_hosts"
      IdentityFile = "~/.ssh/id_ed25519"
      ServerAliveInterval = 60
      ServerAliveCountMax = 3
      Compression = "yes"
      
      # Connection multiplexing
      ControlMaster = "auto"
      ControlPath = "~/.ssh/master-%r@%h:%p"
      ControlPersist = "10m"
    '';
  };

  # Create a wrapper script with useful aliases
  home.file.".local/bin/ssh-connect" = {
    text = ''
      #!/bin/bash
      # Quick SSH connection script
      
      case "$1" in
        "pve-strix")
          ssh root@10.10.11.57 -p 22
          ;;
        "opnsense")
          ssh root@10.10.10.1
          ;;
        "homeserver")
          ssh deepwatrcreatur@10.10.11.69
          ;;
          ;;
        *)
          echo "Available shortcuts: pvestrix, opnsense, homeserver"
          ;;
      esac
    '';
    executable = true;
  };

  # Shell aliases for convenience
  programs.bash.shellAliases = {
    s = "sshs";
    ssh-tui = "sshs";
    connections = "sshs";
  };

  programs.zsh.shellAliases = {
    s = "sshs";
    ssh-tui = "sshs";
    connections = "sshs";
  };

  programs.fish.shellAliases = {
    s = "sshs";
    ssh-tui = "sshs";
    connections = "sshs";
  };

  programs.nushell.shellAliases = {
    s = "sshs";
    ssh-tui = "sshs";
    connections = "sshs";
  };

  # Ensure SSH is properly configured
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    # Global default settings for all hosts
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      
      # Connection multiplexing (matches sshs config)
      controlMaster = "auto";
      controlPath = "~/.ssh/master-%r@%h:%p";
      controlPersist = "10m";
      
      # Performance settings
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
    };
    
    extraConfig = ''
      # Compression
      Compression yes
      
      # Modern algorithms
      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
      HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,ssh-rsa
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    '';
  };
}
