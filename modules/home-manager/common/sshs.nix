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
      
      # SSH connection profiles
      [[hosts]]
      name = "cache-build-server"
      host = "10.10.11.39"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS LXC that builds packages and serves from cache"
      tags = ["server"]
      
      [[hosts]]
      name = "nixoslxc"
      host = "10.10.11.40"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS LXC fresh with my config"

      
      [[hosts]]
      name = "inference1"
      host = "10.10.11.131"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS VM that serves LLM"
      tags = ["inference"]
      
      # SSH connection profiles
      [[hosts]]
      name = "inference2"
      host = "10.10.11.132"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS VM that serves LLM"
      tags = ["inference"]
      
      # SSH connection profiles
      [[hosts]]
      name = "inference3"
      host = "10.10.11.133"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS VM that serves LLM"
      tags = ["inference"]
      
      # SSH connection profiles
      [[hosts]]
      name = "HomeServer"
      host = "10.10.11.69"
      username = "deepwatrcreatur"
      port = 22
      description = "NixOS LXC for services provided to homelab"
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
      name = "pve-strix"
      host = "10.10.11.57"
      username = "root"
      port = 22
      description = "Proxmox host"
      tags = ["homelab"]

      [[hosts]]
      name = "macminim4"
      host = "10.10.11.150"
      username = "deepwatrcreatur"
      port = 22
      description = "macOS desktop"
      
      # Groups for organizing hosts
      [groups]
      homelab = ["pve-strix", "pve-tomahawk", "opnsense", "homeserver", "cache-build-server"]
      inference = ["inference1", "inference2", "inference3"]      
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
        "strix")
          ssh root@10.10.11.57 -p 22
          ;;
        "tomahawk")
          ssh root@10.10.11.55 -p 22
          ;;
        "opnsense")
          ssh root@10.10.10.1
          ;;
        "homeserver")
          ssh deepwatrcreatur@10.10.11.69
          ;;
        "cache")
          ssh deepwatrcreatur@10.10.11.39 -p 22
          ;;
        "inference1")
          ssh deepwatrcreatur@10.10.11.131 -p 22
          ;;
        *)
          echo "Available shortcuts: strix, opnsense, homeserver, cache, tomahawk, inference1"
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
