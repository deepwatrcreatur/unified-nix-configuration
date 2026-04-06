# Bootstrap template configurations for new LXC containers.
#
# These entries use kind = "special" which mkInventoryOutputs does NOT process.
# The actual NixOS outputs are defined manually in outputs/nixos-lxc.nix because
# the bootstrap sequence has unusual requirements (one deliberately omits
# Determinate Nix for the initial container bring-up, then switches post-boot).
#
# mode = "legacy" here reflects that the outputs/nixos-lxc.nix path bypasses
# the den pipeline by design, not due to a migration gap. There is no clear
# den-native equivalent for kind = "special" entries at this time.
#
# Do not attempt to migrate these to aspect mode without first designing a
# den framework path for bootstrap templates that skip Determinate Nix.
{
  nixos_lxc_without_determinate = {
    kind = "special";
    name = "nixos_lxc_without_determinate";
    # Intentionally legacy: actual output is in outputs/nixos-lxc.nix.
    # Bootstrap step 1 - no Determinate Nix, used for initial container creation.
    mode = "legacy";
  };

  nixos_lxc_with_determinate = {
    kind = "special";
    name = "nixos_lxc_with_determinate";
    # Intentionally legacy: actual output is in outputs/nixos-lxc.nix.
    # Bootstrap step 2 - with Determinate Nix, used after initial boot succeeds.
    mode = "legacy";
  };
}
