{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # Ensure /bin/sh is bash
  system.activationScripts.zzzBinShWrapper.text = ''
    rm -f /bin/sh
    cat > /bin/sh <<'EOF'
  #!/run/current-system/sw/bin/bash
  export PATH=/run/current-system/sw/bin:/usr/bin:/bin
  exec /run/current-system/sw/bin/bash "$@"
  EOF
    chmod +x /bin/sh
  '';

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "infisical";

  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.10.11.50";
    prefixLength = 16;
  }];
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.1" ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = true;
  };

  services.mongodb = {
    enable = true;
    bind_ip = "127.0.0.1";
    # port = 27017;
  };

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...yourkey"
    # ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  environment.systemPackages = with pkgs; [
    bashInteractive
    nano
    neovim
    helix
    curl
    git
    gh
    podman
    podman-compose
  ];

  # Set to the latest stable NixOS version you are using!
  system.stateVersion = "24.11";
}
