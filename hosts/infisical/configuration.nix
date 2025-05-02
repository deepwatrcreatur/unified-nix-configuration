{ config, pkgs, ... }:

{
  # Set your hostname
  networking.hostName = "infisical";

  # Set a static IP (adjust interface and addresses as needed)
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.10.11.50";
    prefixLength = 16;
  }];
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.1"];

  # Enable SSH for management
  services.openssh.enable = true;

  # Create a user for SSH (replace with your username and SSH key)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    #openssh.authorizedKeys.keys = [
    #  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...yourkey"
    #];
  };

  # Allow passwordless sudo for wheel group (optional)
  security.sudo.wheelNeedsPassword = false;

  # Enable Docker
  virtualisation.docker.enable = true;

  # (Optional) Enable Avahi for .local hostname discovery
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Minimal system packages
  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    docker-compose
  ];

  # Minimal systemd services
  system.stateVersion = "24.11"; # Set to your NixOS version
}

