{ lib, ... }:

{
  # Declarative CUPS queue so it persists across nixos-rebuild/service restarts.
  # HP PageWide Pro 477dn MFP (2658C2)
  #
  # NixOS manages printers via `hardware.printers.ensurePrinters`.

  services.printing.enable = lib.mkDefault true;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_PageWide_Pro_477dn_MFP_2658C2";
        description = "HP PageWide Pro 477dn MFP (2658C2)";
        location = "Network";

        # Prefer a stable URI over dnssd:// so we don't depend on browsing state.
        deviceUri = "ipp://10.10.10.13/ipp/print";

        # Driverless printing for IPP Everywhere/AirPrint devices.
        # `lpinfo -m | rg -n 'everywhere'` should show the exact available model.
        model = "everywhere";
      }
    ];

    # Avoid "no system default destination" after rebuild.
    ensureDefaultPrinter = lib.mkDefault "HP_PageWide_Pro_477dn_MFP_2658C2";
  };
}
