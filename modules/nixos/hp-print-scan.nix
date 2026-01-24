{
  config,
  lib,
  pkgs,
  ...
}:

{
  # HP printing + scanning support.
  # Works for many HP printers/scanners over USB and network.

  # Printing (CUPS)
  services.printing.enable = lib.mkDefault true;
  services.printing.drivers = with pkgs; [ hplip ];

  # USB printers that expose IPP-over-USB (AirPrint/IPP Everywhere).
  services.ipp-usb.enable = lib.mkDefault true;

  # Scanning (SANE)
  hardware.sane = {
    enable = lib.mkDefault true;
    extraBackends = with pkgs; [
      hplip
      sane-airscan
    ];
  };

  # Discovery for network printers/scanners.
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };

  # Ensure the user can access scanner devices.
  users.users.deepwatrcreatur.extraGroups = lib.mkAfter [
    "lp"
    "scanner"
  ];

  environment.systemPackages = with pkgs; [
    # Printer UI
    system-config-printer

    # HP tools (hp-setup, hp-info, etc.)
    hplip

    # Scanner UI / CLI
    simple-scan
    sane-frontends
  ];
}
