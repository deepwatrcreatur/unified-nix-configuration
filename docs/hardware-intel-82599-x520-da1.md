# Hardware Reference: Intel 82599ES (X520-DA1) Single-Port 10GbE SFP+ Adapter

This reference documents the hardware identity, persistent EEPROM state, and driver configuration for the single-port 10GbE NIC originally deployed in `pve-elitedesk`.

When this card is pulled and reassigned to another homelab host (or spare inventory) as part of migrating `pve-elitedesk` to a dual-port router configuration under NixOS, use this document for setup and driver parameters.

---

## 1. Hardware Identity

| Attribute | Value |
| :--- | :--- |
| **Model** | Intel Ethernet Server Adapter X520-DA1 (Single-Port SFP+) |
| **Controller** | Intel 82599ES 10-Gigabit SFI/SFP+ Network Connection |
| **PCI Vendor / Device ID** | `8086:10fb` (rev 01) |
| **PCI Subsystem ID** | `1b6d:000a` |
| **Printed Board Assembly (PBA)** | `G30771-004` |
| **Permanent MAC Address** | `90:e2:ba:3a:1d:6a` |
| **Device Serial Number** | `90-e2-ba-ff-ff-3a-1d-6a` |
| **PCIe Interface** | PCIe 2.0 x8 (5.0 GT/s, x8 link width) |
| **Port Count** | 1 × SFP+ (10GbE / 1GbE) |

---

## 2. On-Card Firmware & EEPROM Status

* **Firmware Version**: `0x00015e11, 1.3050.0`
* **EEPROM Capabilities Word `0x2c` (Byte Offset `0x58`)**: `0xfffd`
  * **Bit 0 (`IXGBE_DEVICE_CAPS_ALLOW_ANY_SFP`) is permanently set to `1`**.
  * The hardware EEPROM unlock is already present on this physical card.
* **Firmware Location**: The firmware and EEPROM configuration live permanently on the card's non-volatile memory and persist across machine moves, reboots, and OS reinstallations.
* **Boot ROM Backup**: A full SPI flash backup image taken via `flashrom` was archived on `pve-elitedesk` at `/root/ixgbe-82599-backup-20260420-213728.bin`.

---

## 3. OS & Driver Configuration

### Kernel Driver
* **Module**: `ixgbe`
* **Driver Status**: Standard in-tree Linux kernel driver (Linux 6.x+) works out of the box. No out-of-tree patched driver is needed for standard operation.

### NixOS Configuration
To allow non-Intel branded SFP+ transceivers on NixOS, add the driver parameter in your host configuration:

```nix
boot.extraModprobeConfig = ''
  options ixgbe allow_unsupported_sfp=1
'';
```

### Generic Linux (`modprobe.d`)
```bash
echo "options ixgbe allow_unsupported_sfp=1" > /etc/modprobe.d/ixgbe.conf
```

Verify the option is active:
```bash
cat /sys/module/ixgbe/parameters/allow_unsupported_sfp
# Expected: Y
```

### Persistent Interface Naming (systemd-networkd / udev)
To assign a predictable interface name by MAC address:

```ini
# /etc/systemd/network/10-sfp-10g.link
[Match]
MACAddress=90:e2:ba:3a:1d:6a

[Link]
Name=sfp0
```

---

## 4. Tested & Verified Transceiver / Cable Compatibility

### Direct Attach Copper (DAC) Cables
* **Tested Model**: 5-meter passive copper twinax cable (`SFP-H10GB-CU5M`, SFF-8431 Appendix E compliance).
* **Behavior**: Detected as `SFP+: 3` (`ixgbe_sfp_type_da_cu_core0`). Links up immediately at 10000 Mbps full duplex with symmetric flow control.
* **Important Physical Note**: DAC connectors have heavier shielding and latching tabs than optical transceivers. If not pushed firmly until the latch clicks into the cage, the physical I2C pins will fail to make contact, producing kernel errors:
  ```text
  ixgbe ... mgmt0: I2C ack was not received.
  ixgbe ... mgmt0: I2C byte read error.
  ```
  This causes the driver to fall back to `PHY: 1` (`ixgbe_phy_none`) and drop carrier. Reseating the connector firmly resolves this immediately.

### Optical Transceivers (10G Base-SR)
* **Tested Models**: Dely-Tech `SFP-10G-SR` and Blade Network `BN-CKM-SP-SR` (850nm multi-mode LC).
* **Behavior**: Detected as `SFP+: 5` (`ixgbe_sfp_type_srlr_core0`). Links up at 10000 Mbps full duplex.
* **Compatibility Requirement**: Third-party optics must have valid 10G compliance codes in their EEPROM (transceiver compliance byte non-zero). Optics with corrupt or all-zero compliance bytes will require driver-level overrides.

---

## 5. Provenance & History

1. **Origin**: HP EliteDesk 800 G1 SFF (`pve-elitedesk`).
2. **Role**: Served as Proxmox host management interface `mgmt0` connecting to the 10Gb core network.
3. **Reason for Replacement**: Retired from `pve-elitedesk` in favor of a dual-port 10Gb NIC to enable dedicated WAN + LAN routing interfaces when transitioning the machine to a baremetal NixOS router.
