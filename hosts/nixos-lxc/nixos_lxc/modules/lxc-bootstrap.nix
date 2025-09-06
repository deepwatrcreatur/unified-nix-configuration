{ config, lib, pkgs, ... }:

{
  # Bootstrap automation for LXC containers during initial setup
  
  # Ensure /run/current-system symlink is always created
  systemd.services.lxc-system-link = {
    description = "Ensure /run/current-system symlink exists";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/ln -sfn /nix/var/nix/profiles/system /run/current-system";
    };
  };

  # Fix nix profile directory permissions for LXC
  systemd.services.lxc-nix-profiles = {
    description = "Fix Nix profiles directory permissions";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-nix-profiles" ''
        mkdir -p /nix/var/nix/profiles
        chown root:nixbld /nix/var/nix/profiles
        chmod 1775 /nix/var/nix/profiles
      '';
    };
  };

  # Fix sudo setuid permissions for LXC
  systemd.services.lxc-fix-sudo = {
    description = "Fix sudo setuid permissions in LXC";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-sudo-setuid" ''
        # Fix sudo permissions in multiple locations
        for sudo_path in \
          "/run/current-system/sw/bin/sudo" \
          "/run/wrappers/bin/sudo" \
          $(which sudo 2>/dev/null || echo "") \
          $(readlink -f /run/current-system/sw/bin/sudo 2>/dev/null || echo "")
        do
          if [ -n "$sudo_path" ] && [ -f "$sudo_path" ]; then
            echo "Fixing sudo at: $sudo_path"
            chown root:root "$sudo_path" || true
            chmod u+s "$sudo_path" || true
          fi
        done
        
        # Ensure wrappers directory has correct permissions
        if [ -d "/run/wrappers" ]; then
          chown root:root /run/wrappers
          chmod 755 /run/wrappers
        fi
        if [ -d "/run/wrappers/bin" ]; then
          chown root:root /run/wrappers/bin
          chmod 755 /run/wrappers/bin
        fi
      '';
    };
  };

  # Set up proper PATH for root user
  environment.loginShellInit = ''
    export PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/sw/sbin:$PATH
  '';

  # Ensure root has a working shell environment
  users.users.root = {
    shell = lib.mkForce (lib.getExe pkgs.bash);
    extraGroups = [ "wheel" ];
  };

  # Force sudo wrapper to be created with proper permissions in LXC
  security.wrappers = {
    sudo = {
      source = "${pkgs.sudo}/bin/sudo";
      owner = "root";
      group = "root";
      setuid = true;
    };
  };

  # Create a convenience script for entering user environment
  environment.systemPackages = with pkgs; [
    (writeScriptBin "enter-user" ''
      #!${pkgs.bash}/bin/bash
      exec su deepwatrcreatur -s /run/current-system/sw/bin/bash
    '')
  ];

  # Fix PAM and authentication issues in LXC
  security.pam.services = {
    # Enable basic unix authentication for su and sudo
    su.unixAuth = lib.mkForce true;
    sudo.unixAuth = lib.mkForce true;
    login.unixAuth = lib.mkForce true;
    sshd.unixAuth = lib.mkForce true;
  };

  # Ensure authentication works in LXC environment
  users.mutableUsers = lib.mkForce true;
  
  # Fix SSH configuration for LXC
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";  # Allow root login for LXC management
      PasswordAuthentication = false;  # Keep key-only authentication
      PubkeyAuthentication = true;
    };
  };

}