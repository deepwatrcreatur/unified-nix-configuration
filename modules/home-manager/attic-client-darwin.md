# Darwin-specific Attic Client Configuration

This module enables attic-client and nix-user-config by default for all macOS/Darwin systems.

## What it does

- Enables `services.attic-client` (from `modules/home-manager/common/attic-client.nix`)
- Enables `services.nix-user-config` (from `modules/home-manager/common/nix-user-config.nix`)

## Automatically applied

This module is automatically imported for all users on Darwin systems via `modules/nix-darwin/default.nix` using `home-manager.sharedModules`.

## Disabling per-host

If you want to disable attic-client or nix-user-config on a specific Darwin host:

```nix
# users/username/hosts/hostname/default.nix
{
  services.attic-client.enable = false;
  # or
  services.nix-user-config.enable = false;
}
```

## Customizing per-host

To customize settings while keeping it enabled:

```nix
# users/username/hosts/hostname/default.nix
{
  services.attic-client = {
    enable = true;  # Still enabled
    servers = {
      # Override server configuration
      my-custom-server = {
        endpoint = "http://my-server:5001";
        tokenPath = "/path/to/token";
      };
    };
  };

  services.nix-user-config = {
    enable = true;
    substituters = [
      "http://my-cache:5001/cache"
      "https://cache.nixos.org"
    ];
  };
}
```

## Why separate from common modules?

- `common/attic-client.nix` and `common/nix-user-config.nix` are available on all systems but not enabled by default
- This darwin-specific module enables them by default only on macOS systems
- NixOS systems can enable them individually if needed
- Provides flexibility while maintaining sensible defaults
