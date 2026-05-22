{ config, lib, pkgs, ... }:

{
  # Declarative CUPS queue so it persists across nixos-rebuild/service restarts.
  # HP PageWide Pro 477dn MFP (2658C2)
  #
  # NixOS manages printers via `hardware.printers.ensurePrinters`.
  # For driverless IPP printers, `lpadmin` may still exit 1 when the device is
  # offline or temporarily on a different address. Treat that specific status as
  # non-fatal so host rebuilds remain resilient while the queue declaration
  # stays in place.

  systemd.services.ensure-printers.serviceConfig = lib.mkIf config.services.printing.enable {
    SuccessExitStatus = [ 0 1 ];
  };

  services.printing.enable = lib.mkDefault true;

  # Ensure scanning support for this MFP
  hardware.sane = {
    enable = lib.mkDefault true;
    extraBackends = with pkgs; [
      hplip
      sane-airscan
    ];
  };

  # Since Avahi is disabled in the workstation profile, define the scanner
  # explicitly for sane-airscan instead of relying on automatic discovery.
  environment.etc."sane.d/airscan.conf".text = ''
    [devices]
    "HP PageWide Pro 477dn MFP" = http://10.10.21.56:80/eSCL/, eSCL
  '';

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

        # Prefer a stable URI over dnssd:// so we don't depend on browsing
        # state. If the printer is offline or temporarily on a different
        # address, ensure-printers may log an lpadmin failure, but rebuilds
        # should still succeed.
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
