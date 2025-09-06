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
        # Find the current system's sudo binary and fix its permissions
        SUDO_PATH=$(readlink -f /run/current-system/sw/bin/sudo)
        if [ -f "$SUDO_PATH" ]; then
          chown root:root "$SUDO_PATH"
          chmod u+s "$SUDO_PATH"
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
    shell = lib.mkForce pkgs.bash;
    extraGroups = [ "wheel" ];
  };

  # Create a convenience script for entering user environment
  environment.systemPackages = with pkgs; [
    (writeScriptBin "enter-user" ''
      #!${pkgs.bash}/bin/bash
      exec su deepwatrcreatur -s /run/current-system/sw/bin/bash
    '')
  ];

}