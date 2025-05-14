{ config, pkgs, ... }:
{
  networking.hostName = "ansible";
  services.openssh.enable = true;
  users.users.ansible = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "secret"; # or use hashedPassword
  };
  environment.systemPackages = with pkgs; [
    ansible
    git
  ];
}
