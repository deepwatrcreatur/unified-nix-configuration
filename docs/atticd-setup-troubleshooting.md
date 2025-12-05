# Atticd Setup and Troubleshooting Guide

This guide documents the issues encountered and solutions implemented when setting up atticd (Attic binary cache daemon) in NixOS with Home Manager integration.

## Overview

Setting up atticd in NixOS involves several interconnected systems:
- NixOS systemd service management
- StateDirectory and RuntimeDirectory management  
- Environment file handling for secrets
- Database permissions and user isolation
- Home Manager integration with sops-nix

## Issues Encountered and Solutions

### 1. Home Manager sops-nix Integration Conflicts

**Problem**: Home Manager failed to activate due to sops-nix module conflicts and missing service dependencies.

**Symptoms**:
```
× home-manager-root.service - Home Manager environment for root
Failed to restart sops-nix.service: Unit sops-nix.service not found.
```

**Root Cause**: 
- sops-nix.service doesn't exist in newer sops-nix versions (secrets are installed during activation)
- Home Manager shared modules trying to load sops-nix for all users
- Conflicting sops configurations between system-level and user-level

**Solutions**:
1. **Removed non-existent service dependencies**:
   ```nix
   # BEFORE (broken):
   systemd.services.some-service = {
     after = [ "sops-nix.service" ];
     requires = [ "sops-nix.service" ];
   };
   
   # AFTER (working):
   systemd.services.some-service = {
     after = [ "atticd.service" ];
   };
   ```

2. **Disabled conflicting Home Manager sops shared modules**:
   ```nix
   # BEFORE (broken):
   home-manager.sharedModules = [
     inputs.sops-nix.homeManagerModules.sops
   ];
   
   # AFTER (working):
   # home-manager.sharedModules = [
   #   inputs.sops-nix.homeManagerModules.sops
   # ];
   ```

3. **Made sops configurations conditional in modules**:
   ```nix
   # BEFORE (broken):
   sops.secrets."some-secret" = { ... };
   
   # AFTER (working):
   # Temporarily disabled sops configurations that depend on the module
   # sops.secrets."some-secret" = { ... };
   ```

### 2. SystemD StateDirectory Permission Conflicts

**Problem**: atticd.service failed with "STATE_DIRECTORY" errors due to manual directory management conflicting with systemd's declarative approach.

**Symptoms**:
```
atticd.service: Failed to set up special execution directory in /var/lib: File exists
atticd.service: Failed at step STATE_DIRECTORY spawning atticd: File exists
Main process exited, code=exited, status=238/STATE_DIRECTORY
```

**Root Cause**: 
- Manual creation of `/var/lib/atticd` with wrong ownership
- SystemD's StateDirectory feature conflicted with existing directories
- Mixed imperative and declarative directory management

**Solution**:
Use NixOS's declarative approach instead of manual directory management:

```nix
# BEFORE (broken imperative approach):
systemd.services.attic-token-setup = {
  script = ''
    mkdir -p /var/lib/atticd  # Manual directory creation
    touch /var/lib/atticd/env
    chmod 600 /var/lib/atticd/env
  '';
};

# AFTER (working declarative approach):
services.atticd = {
  enable = true;
  environmentFile = "/etc/atticd.env";  # Let NixOS manage this
  settings = { ... };
};

# Remove conflicting manual systemd overrides:
# systemd.services.atticd = {  # Don't override what NixOS manages
#   serviceConfig.StateDirectory = "atticd";
#   serviceConfig.RuntimeDirectory = "atticd";
# };
```

### 3. Environment File Management 

**Problem**: Environment files containing secrets were managed imperatively, causing startup failures and security issues.

**Symptoms**:
```
atticd.service: Failed to load environment files: No such file or directory
atticd.service: Failed to spawn 'start' task: No such file or directory
atticd.service: Failed with result 'resources'.
```

**Root Cause**:
- Environment file path inconsistencies 
- Manual file creation racing with systemd service startup
- Hardcoded secrets in configuration files

**Solutions**:

1. **Use NixOS declarative environment file management**:
   ```nix
   # BEFORE (broken):
   environmentFile = "/var/lib/atticd/env";  # Path in StateDirectory
   
   # AFTER (working):
   environmentFile = "/etc/atticd.env";      # Managed by environment.etc
   
   environment.etc."atticd.env" = {
     text = ''
       ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="..."
     '';
     mode = "0600";
   };
   ```

2. **Better approach - Use sops-nix for secret management** (recommended for production):
   ```nix
   sops.secrets."attic-server-token" = {
     sopsFile = ../../../../secrets/attic-server-token.txt.enc;
     format = "binary";
   };
   
   systemd.services.atticd-env-setup = {
     before = [ "atticd.service" ];
     script = ''
       echo "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$(cat ${config.sops.secrets."attic-server-token".path})" > /etc/atticd.env
       chmod 600 /etc/atticd.env
     '';
   };
   ```

### 4. Database Permission Issues

**Problem**: SQLite database creation failures due to systemd user isolation.

**Symptoms**:
```
Error: Database error: Connection Error: (code: 14) unable to open database file
```

**Root Cause**:
- SystemD's PrivateUsers=true creates user namespace isolation
- StateDirectory ownership issues with DynamicUser=true
- Old directory permissions preventing database file creation

**Solution**:
Clean slate approach - remove existing directories and let systemd recreate them:

```bash
# Clean up existing directories
sudo systemctl stop atticd.service
sudo rm -rf /var/lib/atticd /var/lib/private/atticd

# Let systemd handle directory creation with proper permissions
sudo systemctl start atticd.service
```

The NixOS atticd module properly handles:
- User/group creation (`atticd:atticd`)
- StateDirectory management with correct ownership
- PrivateUsers isolation mapping

## Proper NixOS Declarative Pattern

The correct way to set up atticd in NixOS follows the official documentation pattern:

```nix
{
  services.atticd = {
    enable = true;
    environmentFile = "/etc/atticd.env";
    settings = {
      listen = "[::]:8080";
      jwt = { };
      
      # Database configuration - let systemd handle the directory
      database.url = "sqlite:///var/lib/atticd/server.db";
      
      # Storage configuration - let systemd handle the directory  
      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };
      
      chunking = {
        nar-size-threshold = 64 * 1024;  # 64 KiB
        min-size = 16 * 1024;            # 16 KiB
        avg-size = 64 * 1024;            # 64 KiB
        max-size = 256 * 1024;           # 256 KiB
      };
    };
  };

  # Proper secret management with sops-nix
  sops.secrets."attic-server-token" = {
    sopsFile = ./secrets/attic-server-token.txt.enc;
    format = "binary";
  };

  # Create environment file that references the secret
  environment.etc."atticd.env" = {
    text = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$(cat ${config.sops.secrets."attic-server-token".path})
    '';
    mode = "0600";
  };
}
```

## Key Principles

1. **Use NixOS modules instead of manual systemd configuration**: The `services.atticd` module handles all the systemd service details correctly.

2. **Let systemd manage directories**: Don't manually create StateDirectory/RuntimeDirectory - let systemd handle ownership and permissions.

3. **Separate concerns**: Keep system-level configuration (atticd service) separate from user-level configuration (Home Manager).

4. **Use declarative secret management**: Avoid hardcoding secrets. Use sops-nix or similar for production deployments.

5. **Follow the dependency chain**: Ensure proper service ordering (sops-install-secrets → env-setup → atticd → attic-init).

### 5. SQLite Database URL Mode Parameter Issue

**Problem**: atticd service fails to create SQLite database due to missing mode parameter.

**Symptoms**:
```
Error: Database error: Connection Error: (code: 14) unable to open database file
```

**Root Cause**: 
- SQLite database URL missing required `?mode=rwc` parameter for read-write-create access
- SystemD's security isolation (DynamicUser, PrivateUsers) requires explicit SQLite mode specification

**Solution**:
```nix
# BEFORE (broken):
database.url = "sqlite:///var/lib/atticd/server.db";

# AFTER (working):
database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
```

This issue is not well-documented in online sources because most examples assume manual setup without systemd's security isolation features.

### 6. Home Manager Module Configuration Conflicts

**Problem**: Home Manager modules with `default = true` still create configuration files even when explicitly disabled.

**Symptoms**:
```
Existing file '/root/.config/attic/config.toml' would be clobbered
home-manager-root.service: Failed with result 'exit-code'.
```

**Root Cause**:
- Home Manager auto-import system loads all modules from `modules/home-manager/common/`
- Module has `default = true` setting that conflicts with explicit `enable = false`
- The `config = lib.mkIf cfg.enable` wrapper should prevent file creation but doesn't work as expected

**Current Investigation**:
The attic-client.nix module structure appears correct with proper conditional wrapping:
```nix
config = lib.mkIf cfg.enable {
  home.file.".config/attic/config.toml".text = ...;
};
```

But the file is still being created despite `services.attic-client.enable = false;` in the user's configuration.

**Potential Solutions** (under investigation):
1. Check for module import conflicts or evaluation order issues
2. Add explicit `lib.mkIf cfg.enable` around individual file declarations
3. Consider using `lib.mkForce false` in user configuration
4. Add `force = true` to Home Manager file configuration as suggested by error message

### 7. Attic Cache Authentication Issues - JWT Algorithm Mismatch

**Problem**: attic-init.service successfully logs in but fails to create cache with "Unauthorized" error.

**Symptoms**:
```
Successfully logged into Attic server
Creating cache-local...
Error: Unauthorized: Unauthorized.
```

**Root Cause**: 
The JWT signing algorithm mismatch between server and client tokens:
- Server was configured with an RSA private key (for RS256 signing)
- But the environment variable was set as `ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64` (HMAC)
- Client tokens were generated with HS256 algorithm
- Server couldn't verify client tokens because it expected RS256 signatures

**Solution**:

1. **Fix the server environment variable** to use RS256:
   ```nix
   # BEFORE (broken - algorithm mismatch):
   echo "ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=$JWT_SECRET" > /etc/atticd.env
   
   # AFTER (working - correct algorithm):
   echo "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$JWT_SECRET" > /etc/atticd.env
   ```

2. **Regenerate client tokens** using RS256 with `atticd-atticadm`:
   ```bash
   # Generate new admin token with RS256 (must match server's key)
   atticd-atticadm make-token \
     --config /nix/store/...-checked-attic-server.toml \
     --sub admin-user \
     --validity "2 years" \
     --pull '*' --push '*' --delete '*' \
     --create-cache '*' --configure-cache '*' \
     --configure-cache-retention '*' --destroy-cache '*'
   ```

3. **Update SOPS secret** with the new RS256 token:
   ```bash
   # Copy encrypted file to .yaml for sops to recognize format
   cp secrets/attic-server-token.yaml.enc /tmp/test.yaml
   
   # Update the token value
   sops set /tmp/test.yaml '["ATTIC_SERVER_TOKEN"]' '"eyJhbGciOiJSUzI1NiI..."'
   
   # Copy back
   cp /tmp/test.yaml secrets/attic-server-token.yaml.enc
   ```

**Key Insight**: When using an RSA private key as your JWT secret, you MUST:
- Use `ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64` (not HS256)
- Generate client tokens with `atticd-atticadm` which uses the same key
- Ensure all tokens use the RS256 algorithm (check JWT header: `"alg":"RS256"`)

### 8. Attic Cache Configure Command Changes

**Problem**: `attic cache configure` fails with unknown argument error.

**Symptoms**:
```
error: unexpected argument '--upstream-cache-uris' found
  tip: a similar argument exists: '--upstream-cache-key-name'
```

**Root Cause**: 
The `--upstream-cache-uris` option was removed in newer versions of attic-client. The upstream cache URIs are now configured differently.

**Solution**:
Remove the `--upstream-cache-uris` argument from cache configuration:
```nix
# BEFORE (broken - deprecated argument):
${pkgs.attic-client}/bin/attic cache configure cache-local \
    --upstream-cache-key-name cache.nixos.org-1 \
    --upstream-cache-uris https://cache.nixos.org

# AFTER (working):
${pkgs.attic-client}/bin/attic cache configure cache-local \
    --upstream-cache-key-name cache.nixos.org-1
```

The `--upstream-cache-key-name` is sufficient - it tells attic to skip paths already signed by that key when pushing.

## Resolution Progress Summary

### Completed Fixes:
1. ✅ **Syntax errors in flake.nix** - Fixed trailing commas and module imports
2. ✅ **Home Manager sops-nix integration conflicts** - Disabled conflicting shared modules
3. ✅ **Non-existent service dependencies** - Removed references to sops-nix.service
4. ✅ **SystemD StateDirectory conflicts** - Used declarative NixOS patterns
5. ✅ **Environment file management** - Moved to `/etc/atticd.env` with proper permissions
6. ✅ **SQLite database permission issues** - Added `?mode=rwc` parameter
7. ✅ **atticd.service startup** - Service now starts successfully
8. ✅ **JWT algorithm mismatch** - Changed from HS256 to RS256, regenerated tokens
9. ✅ **Deprecated cache configure args** - Removed `--upstream-cache-uris`

### Remaining Issues:
1. 🔄 **Home Manager attic config file conflict** - Module disable not working properly

### Current Status:
- **atticd.service**: ✅ Running successfully 
- **attic-init.service**: ✅ Cache initialized successfully
- **home-manager-root.service**: ❌ File conflict with `/root/.config/attic/config.toml`

## Troubleshooting Commands

```bash
# Check service status
systemctl status atticd.service home-manager-root.service attic-init.service

# View recent logs
journalctl -u atticd.service -n 20
journalctl -u home-manager-root.service -n 20
journalctl -u attic-init.service -n 20

# Check directory permissions
ls -la /var/lib/atticd /var/lib/private/atticd

# Check environment file
sudo cat /etc/atticd.env

# Check Home Manager file conflicts
ls -la /root/.config/attic/

# Test configuration syntax
nixos-rebuild dry-build --flake .

# Clean rebuild
sudo systemctl stop atticd.service
sudo rm -rf /var/lib/atticd /var/lib/private/atticd  
nixos-rebuild switch --flake .

# Debug Home Manager module evaluation
home-manager --flake .#cache-build-server.root build --show-trace
```

## References

- [Official Attic NixOS Deployment Guide](https://docs.attic.rs/admin-guide/deployment/nixos.html)
- [NixOS Manual - systemd Services](https://nixos.org/manual/nixos/stable/#sec-systemd-services)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)