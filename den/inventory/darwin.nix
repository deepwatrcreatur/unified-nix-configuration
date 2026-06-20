# Darwin (macOS) host inventory.
#
# These entries are consumed by mkInventoryOutputs -> mkDarwinOutput, so
# non-archived entries participate in the den output pipeline. They remain
# mode = "legacy" because the den aspects system (den/aspects/) covers NixOS
# only. There are no darwin-specific aspects for dock, finder, security, or
# macOS package management.
#
# Migration path: define darwin-specific aspects (e.g. darwin-base, darwin-dock)
# and move macminim4's host modules into aspect files. This is blocked on the
# darwin aspect infrastructure being designed first.
#
# hackintosh: NOT present in lib/hosts.nix. This is an archived/inactive system.
# It has a hosts/hackintosh/ directory but is no longer deployed. Kept here as
# inventory history, but archived entries are skipped by mkInventoryOutputs.
#
# macminim4: Active macOS machine. Intentionally legacy until darwin aspects exist.
{
  hackintosh = {
    kind = "darwin";
    name = "hackintosh";
    system = "x86_64-darwin";
    hostPath = ../../hosts/hackintosh;
    username = "deepwatrcreatur";
    archived = true;
    # Intentionally legacy: no darwin aspects exist yet. Also likely inactive —
    # hackintosh is not in lib/hosts.nix and has no recent maintenance.
    mode = "legacy";
  };

  macminim4 = {
    kind = "darwin";
    name = "macminim4";
    system = "aarch64-darwin";
    hostPath = ../../hosts/macminim4;
    username = "deepwatrcreatur";
    # Intentionally legacy: no darwin aspects exist yet. Active machine;
    # migrate to aspect mode once darwin-base and related aspects are defined.
    mode = "legacy";
  };
}
