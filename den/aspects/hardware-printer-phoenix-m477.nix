# den/aspects/hardware-printer-phoenix-m477.nix
# HP PageWide Pro 477dn MFP printer and scanner configuration
{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/hp-print-scan.nix
    ../../modules/nixos/printers/phoenix-hp-m477.nix
  ];
}
