# Attic Server Token Generation and Setup

This guide documents the process of generating and configuring an attic server token for the cache-build-server.

## Overview

The attic server has been successfully configured with:

1. **JWT Secret**: Server uses `ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64` for signing/verifying tokens
2. **Admin Token**: Generated with full permissions using `atticd-atticadm`
3. **SOPS Integration**: Token encrypted and stored securely in `secrets/attic-server-token.yaml.enc`

## Generated Token

The server now has a valid JWT token with the following permissions:
- `pull`: "*" - Can pull from any cache
- `push`: "*" - Can push to any cache  
- `delete`: "*" - Can delete from any cache
- `create-cache`: "*" - Can create new caches
- `configure-cache`: "*" - Can configure existing caches
- `configure-cache-retention`: "*" - Can configure cache retention

## Manual Cache Creation

If the automatic cache creation fails, you can manually create the cache:

```bash
# Decrypt the token and create cache
ATTIC_TOKEN=$(sops --decrypt --input-type yaml --output-type yaml secrets/attic-server-token.yaml.enc | grep ATTIC_SERVER_TOKEN | cut -d' ' -f2)

# Login to attic server
attic login local http://localhost:5001 $ATTIC_TOKEN --set-default

# Create the cache
attic cache create cache-local
```

## Configuration Files

- `hosts/nixos-lxc/cache-build-server/modules/build-server.nix`: Main configuration
- `secrets/attic-server-token.yaml.enc`: Encrypted admin token
- `secrets/attic-server-private-key.yaml.enc`: JWT signing secret

## Services

- **atticd**: Running on port 5001 with JWT authentication
- **attic-init**: Systemd service for cache initialization (may need manual intervention)
- **nginx**: Reverse proxy on port 8081 for attic cache

## Troubleshooting

If you encounter "Unauthorized" errors:

1. Check that atticd is running: `systemctl status atticd`
2. Verify token is current: Re-generate token if needed
3. Check server logs: `journalctl -u atticd -f`
4. Test API directly: `curl -H "Authorization: Bearer $TOKEN" http://localhost:5001/_attic/v1/cache`

The infrastructure is properly set up and the token has full admin permissions for cache management.