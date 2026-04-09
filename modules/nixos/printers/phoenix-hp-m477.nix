{ lib, ... }:

{
  # Declarative CUPS queue so it persists across nixos-rebuild/service restarts.
  # HP PageWide Pro 477dn MFP (2658C2)
  #
  # NixOS manages printers via `hardware.printers.ensurePrinters`.

  services.printing.enable = lib.mkDefault true;

  # Ensure scanning support for this MFP
  hardware.sane = {
    enable = lib.mkDefault true;
    extraBackends = with pkgs; [
      hplip
      sane-airscan
    ];
    # Since Avahi is disabled in the profile, we manually define the scanner IP
    config.airscan = {
      "HP PageWide Pro 477dn MFP" = "http://10.10.21.56:80/eSCL/";
    };
  };

  environment.systemPackages = with pkgs; [
    simple-scan
    hplip
  ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_PageWide_Pro_477dn_MFP_2658C2";
        description = "HP PageWide Pro 477dn MFP (2658C2)";
        location = "Network";

        # Prefer a stable URI over dnssd:// so we don't depend on browsing state.
        # If you get a "Host is down" error from `ensure-printers.service`,
        # check that the printer is online and reachable from this host, e.g., `ping 10.10.21.56`.
        deviceUri = "ipp://10.10.21.56/ipp/print";

        # Driverless printing for IPP Everywhere/AirPrint devices.
        # `lpinfo -m | rg -n 'everywhere'` should show the exact available model.
        model = "everywhere";
      }
    ];

    # Avoid "no system default destination" after rebuild.
    ensureDefaultPrinter = lib.mkDefault "HP_PageWide_Pro_477dn_MFP_2658C2";
  };
}
