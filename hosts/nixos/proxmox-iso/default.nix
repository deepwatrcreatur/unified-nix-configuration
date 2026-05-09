{ pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # Enable SSH and allow the key
  services.openssh.enable = true;
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI deepwatrcreatur@gmail.com"
  ];

  # Optional: add some useful tools
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Networking
  networking.hostName = "proxmox-iso";

  # Hardware configuration for standard VM
  nixpkgs.hostPlatform = "x86_64-linux";
}
