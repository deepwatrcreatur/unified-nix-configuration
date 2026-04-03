# Router Kea Module Roadmap

This roadmap defines the proposed structure for the `router-kea` module in `nix-router-optimized`, allowing optional and robust DHCP/DDNS support.

## Proposed Module Boundaries

To maintain modularity and optionality, we will use a single main module with sub-options, rather than multiple separate modules.

- **Module Name**: `router-kea`
- **Location**: `nix-router-optimized/modules/router-kea.nix`

## Candidate Option Schema

```nix
{
  options.services.router-kea = {
    enable = mkEnableOption "Kea DHCP services";

    dhcp4 = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DHCPv4 server.";
      };
      
      # Interfaces to listen on, automatically derived from router-networking if not set
      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ]; 
      };

      pools = mkOption {
        type = types.listOf (types.submodule {
          options = {
            pool = mkOption { type = types.str; };
            # Add options for specific subnet options (gateway, dns, etc.)
          };
        });
        default = [ ];
      };

      reservations = mkOption {
        type = types.listOf (types.submodule {
          options = {
            hw-address = mkOption { type = types.str; };
            ip-address = mkOption { type = types.str; };
            hostname = mkOption { type = types.nullOr types.str; default = null; };
          };
        });
        default = [ ];
      };
    };

    ddns = {
      enable = mkEnableOption "Kea DHCP-DDNS (D2) integration";
      
      dnsServer = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "DNS server to update via RFC2136.";
      };

      tsigKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to the TSIG key file for secure updates.";
      };

      domain = mkOption {
        type = types.str;
        description = "Domain name for DDNS updates.";
      };
    };

    ha = {
      enable = mkEnableOption "Kea High Availability";
      
      role = mkOption {
        type = types.enum [ "primary" "standby" ];
        default = "primary";
      };

      peerAddress = mkOption {
        type = types.str;
        description = "IP address of the Kea peer.";
      };
    };
  };
}
```

## What to Upstream First (Phase 1)

1. **Base `router-kea` Module**: Basic DHCPv4 support with pool and reservation modeling.
2. **Firewall Integration**: Automatically opening the required DHCP ports (67/UDP) in `router-firewall`.
3. **Interface Integration**: Automatic binding to interfaces defined in `router-networking`.

## What to Keep Repo-Local (Phase 2)

1. **Specific HA Configuration**: The exact TSIG keys and peer addresses for `router` and `router-backup`.
2. **Technitium-specific DDNS tuning**: Any specific TSIG or zone settings required for Technitium.
3. **Migration Logic**: Scripts to transition from Technitium DHCP to Kea.

## Integration Points

- **router-networking**: `router-kea` should read `config.services.router-networking.routedInterfaces` to identify which interfaces require DHCP services.
- **router-firewall**: Should automatically permit DHCP traffic on the relevant interfaces.
- **router-dashboard**: Should eventually show Kea lease statistics or status.

## Implementation Steps

1. Create `router-kea.nix` in `nix-router-optimized`.
2. Implement basic DHCPv4 functionality.
3. Add DDNS support via D2.
4. Add HA support via Kea hooks.
5. Provide a way to easily port existing `router-technitium` reservations to `router-kea`.
