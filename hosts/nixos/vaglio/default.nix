{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
  ];

  my.agenix.machineIdentity.enable = true;
  age.identityPaths = lib.mkForce [ "/var/lib/agenix/machine-identity" ];

  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
      extraConfig = ''
        serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
        terminal_input serial console
        terminal_output serial console
      '';
    };
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];
  };

  systemd.services."serial-getty@ttyS0".enable = true;
  systemd.services.qemu-guest-agent.wantedBy = [ "multi-user.target" ];

  networking.firewall.enable = lib.mkForce false;
}
