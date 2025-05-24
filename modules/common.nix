# Common settings applied to ALL machines defined in flake.nix
{ config, pkgs, lib, inputs, ... }: {
  imports = [
    # Import user definitions (if common across hosts)
    ../users/common.nix
    ./just.nix
  ];

  # Basic System Settings
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_US.UTF-8";

  # Base packages available system-wide
  environment.systemPackages = with pkgs; [
    wget
    curl
    neovim
    htop
    btop
    # Add packages needed on *all* your systems
  ];

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true; # Recommended: use key-based auth
    settings.KbdInteractiveAuthentication = true;
  };

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Systemd journal settings
  services.journald.extraConfig = ''
    SystemMaxUse=50M
    RuntimeMaxUse=50M
  '';

  system.stateVersion = "24.11"; # Set to the version you initially installed
}

