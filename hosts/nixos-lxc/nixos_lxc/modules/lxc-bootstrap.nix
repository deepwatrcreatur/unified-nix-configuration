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

  # Enable SSH daemon for remote access
  services.openssh = {
    enable = true;
    startWhenNeeded = false;  # Force persistent daemon instead of socket activation
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Open SSH port in firewall
  networking.firewall.allowedTCPPorts = [ 22 ];
}