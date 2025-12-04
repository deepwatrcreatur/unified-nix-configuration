{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  system.activationScripts.zzzBinShWrapper.text = ''
    rm -f /bin/sh
    cat > /bin/sh <<'EOF'
  #!/run/current-system/sw/bin/bash
  export PATH=/run/current-system/sw/bin:/usr/bin:/bin
  exec /run/current-system/sw/bin/bash "$@"
  EOF
    chmod +x /bin/sh
  '';

  networking.hostName = "nixos-lxc";

  # Set a static IP (adjust interface and addresses as needed)
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.10.11.50";
    prefixLength = 16;
  }];
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.1"];

  # Enable SSH for management
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";           # Allow root login
    settings.PasswordAuthentication = true;     # Allow password authentication
  };
  # Create a user for SSH (replace with your username and SSH key)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    #openssh.authorizedKeys.keys = [
    #  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...yourkey"
    #];
  };

  # Allow passwordless sudo for wheel group (optional)
  security.sudo.wheelNeedsPassword = false;

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
    bashInteractive
    nano
    neovim
    helix
    curl
    git
    gh
  ];

  # Minimal systemd services
  system.stateVersion = "25.05"; # Set to your NixOS version
}
