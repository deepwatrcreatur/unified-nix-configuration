# vDSO Error Fix for Ubuntu with Nix

## Problem

When running Nix-installed programs on Ubuntu (including LTS kernels like 6.8.0-87 and mainline 6.12.x), you may encounter errors like:

```
error while loading shared libraries: __vdso_time: invalid mode for dlopen(): Invalid argument
error while loading shared libraries: __vdso_gettimeofday: invalid mode for dlopen(): Invalid argument
*** stack smashing detected ***: terminated
```

This affects programs like `fish`, `gpg`, `coreutils`, `zellij`, `atuin`, and other Nix-installed binaries.

## Root Cause

This error can occur due to several causes:

1. **Kernel vDSO regression** (Linux 6.12.0-6.12.3) - A specific bug in these kernel versions
2. **Ubuntu kernel security patches** - Ubuntu's HWE kernels (like 6.8.0-87) include security hardening that can conflict with Nix's glibc
3. **Corrupted Nix store** - Can happen after system updates or power failures
4. **AppArmor/Security module interference** - Ubuntu's security modules may block certain operations

The vDSO (virtual dynamic shared object) is a kernel feature that provides fast implementations of certain system calls. When there's a mismatch between the kernel's vDSO and glibc's expectations, these errors occur.

## Solutions

### Solution 1: Repair Nix Installation (Try First)

Often the issue is a corrupted Nix store or daemon state:

```bash
# Restart the Nix daemon
sudo systemctl restart nix-daemon

# Verify Nix store integrity
nix-store --verify --check-contents

# Repair if needed
nix-store --verify --check-contents --repair

# Clear and rebuild user profile
rm -rf ~/.nix-profile
nix-env --switch-profile /nix/var/nix/profiles/default
```

### Solution 2: Reinstall Nix (If Repair Fails)

```bash
# Backup your configuration
cp -r ~/.config/nix ~/.config/nix.backup

# Uninstall Nix (Determinate Systems installer)
/nix/nix-installer uninstall

# Or for official installer
# Follow: https://nixos.org/manual/nix/stable/installation/uninstall.html

# Reinstall
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restore configuration
cp -r ~/.config/nix.backup/* ~/.config/nix/
```

### Solution 3: Upgrade Kernel (For 6.12.0-6.12.3 Users)

If you're on Linux 6.12.0-6.12.3, the vDSO issue was **fixed in kernel 6.12.4+**.

**For Ubuntu with mainline kernels:**

```bash
# Check current kernel version
uname -r

# Install Ubuntu Mainline Kernel Installer (if not already installed)
sudo add-apt-repository ppa:cappelikan/ppa
sudo apt update
sudo apt install mainline

# Use the GUI to install kernel 6.12.4+ or 6.13+
mainline --install 6.12.4
# Or for latest stable
mainline --install-latest

# Reboot
sudo reboot
```

**Manual mainline kernel installation:**

```bash
# Download from https://kernel.ubuntu.com/mainline/
# Example for 6.12.4:
cd /tmp
wget https://kernel.ubuntu.com/mainline/v6.12.4/amd64/linux-headers-6.12.4-061204_6.12.4-061204.202412111536_all.deb
wget https://kernel.ubuntu.com/mainline/v6.12.4/amd64/linux-headers-6.12.4-061204-generic_6.12.4-061204.202412111536_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.12.4/amd64/linux-image-unsigned-6.12.4-061204-generic_6.12.4-061204.202412111536_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.12.4/amd64/linux-modules-6.12.4-061204-generic_6.12.4-061204.202412111536_amd64.deb

sudo dpkg -i *.deb
sudo reboot
```

### Solution 4: Downgrade Kernel (For 6.12.x Users)

If you're on 6.12.0-6.12.3 and upgrading isn't possible, downgrade to an earlier kernel:

```bash
# List available kernels
apt list --installed | grep linux-image

# Install an older kernel (example for Ubuntu)
sudo apt install linux-image-6.8.0-49-generic linux-headers-6.8.0-49-generic

# Reboot and select the older kernel from GRUB
sudo reboot
```

To make the older kernel default:

```bash
# Edit GRUB configuration
sudo nano /etc/default/grub

# Change GRUB_DEFAULT to the menu entry of the older kernel
# For example: GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.8.0-49-generic"

# Update GRUB
sudo update-grub
sudo reboot
```

### Solution 5: Disable vDSO (Last Resort Workaround)

If you cannot change the kernel, you can disable vDSO as a workaround. This has a **minor performance impact** but resolves the issue:

```bash
# Temporary fix (until reboot)
sudo sysctl -w vm.vdso_enabled=0

# Permanent fix
echo "vm.vdso_enabled=0" | sudo tee /etc/sysctl.d/99-disable-vdso.conf
sudo sysctl -p /etc/sysctl.d/99-disable-vdso.conf
```

**Note:** On some systems, the sysctl parameter might be:
- `vm.vdso_enabled` (older kernels)
- `kernel.vdso` (some distributions)

If neither works, try:

```bash
# Check available vdso parameters
sudo sysctl -a | grep -i vdso
```

### Solution 6: Use System Binaries Temporarily

As a temporary workaround, use Ubuntu's system binaries instead of Nix ones:

```bash
# Use system bash instead of Nix fish
/bin/bash

# Or set PATH to prefer system binaries
export PATH="/usr/bin:/bin:$PATH"
```

## Verification

After applying a fix, verify it works:

```bash
# Test a Nix binary
/nix/store/*/bin/cat --version

# Or start fish
fish
```

## Kernel Version Summary

| Kernel Version | Status | Notes |
|----------------|--------|-------|
| Ubuntu 6.8.0-87 (LTS) | ⚠️ May have issues | Try Solution 1 or 2 first |
| 6.11.x and earlier | ✅ Generally works | |
| 6.12.0 - 6.12.3 | ❌ Broken | vDSO regression |
| 6.12.4+ | ✅ Fixed | |
| 6.13+ | ✅ Fixed | |

## Related Issues

- This issue specifically affects Nix binaries because they use a different glibc than the host system
- NixOS systems are not affected because the kernel and glibc are built together
- The issue may also affect other systems using statically-linked or bundled glibc (AppImages, Flatpaks, etc.)

## Ubuntu LTS Specific Notes

For Ubuntu 24.04 LTS with kernel 6.8.0-87:

1. **This kernel should generally work** - The 6.8.x series doesn't have the 6.12 vDSO regression
2. **If you see these errors**, it's likely a Nix installation issue, not a kernel bug
3. **Try Solutions 1 and 2 first** - Repair or reinstall Nix before changing kernels
4. **Check for recent updates** - If errors started after `apt upgrade`, a kernel update may have caused issues

```bash
# Check when kernel was last updated
ls -la /boot/vmlinuz-*

# Check Nix daemon status
systemctl status nix-daemon

# Check for AppArmor denials
sudo dmesg | grep -i apparmor | tail -20
```

## References

- Linux kernel vDSO documentation: https://www.kernel.org/doc/html/latest/x86/vdso.html
- Nix on non-NixOS systems: https://nixos.wiki/wiki/Nix_on_non-NixOS
- Ubuntu Mainline Kernels: https://kernel.ubuntu.com/mainline/
- Kernel changelog for 6.12.4: https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.12.4
- NixOS Discourse (troubleshooting): https://discourse.nixos.org/