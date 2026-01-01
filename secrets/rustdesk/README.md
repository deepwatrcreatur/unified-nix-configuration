# RustDesk Server Configuration

This directory contains RustDesk server configuration and key information.

## Public Key

The RustDesk server uses Ed25519 keypairs for client verification. The server's public key fingerprint should be verified by clients when first connecting.

### Getting the Server's Public Key

After the RustDesk server is deployed, get the public key with:

```bash
ssh rustdesk "cat /etc/rustdesk/id_ed25519.pub"
```

Or if you have root access:

```bash
ssh root@rustdesk "cat /etc/rustdesk/id_ed25519.pub"
```

The output will look like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx rustdesk@rustdesk
```

### Client Verification

When connecting with a RustDesk client to `your-rustdesk-ip:21115`:

1. Client will show you the server's public key fingerprint
2. Compare it with the fingerprint above
3. Accept the connection - this establishes trust

### Server Configuration Files

RustDesk server stores its configuration and keys in:
- `/etc/rustdesk/` - Server configuration directory
  - `id_ed25519` - Private key (kept secure)
  - `id_ed25519.pub` - Public key (safe to share)
  - `hbbs.toml` - Signal server configuration
  - `hbbr.toml` - Relay server configuration

## Users

The RustDesk server has the following configured user:
- `deepwatrcreatur` - Primary user for remote desktop access
  - Member of `wheel` group (sudo access)
  - Shell: Fish

To set/reset password on RustDesk server:

```bash
ssh root@rustdesk "passwd deepwatrcreatur"
```

## Next Steps

1. Deploy RustDesk configuration to container
2. Verify server is running: `systemctl status rustdesk-server`
3. Get the public key using commands above
4. Configure clients (macminim4, workstation) to connect
5. Workstation will control macminim4 via RustDesk relay

## Network Configuration

- **Server IP**: Check with `lxc list` or your network DHCP
- **Ports**:
  - 21115: TCP (Control)
  - 21116: TCP (File transfer)
  - 21117: TCP (Audio)
  - 21118: TCP (Keyboard/mouse)
  - 21119: TCP (Clipboard)
  - 5443: TCP (Relay)
