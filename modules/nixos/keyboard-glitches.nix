# Fix for stuck keyboard presses in NixOS running as a guest on Proxmox
#
# This module addresses the common "stuck key" or "key repeat" bug caused by
# desync between keyboard's "key down" and "key up" events over the virtualized
# interface.
#
# Reference: https://github.com/NixOS/nixpkgs/issues/103746
{
  config,
  lib,
  ...
}:

{
  options = {
    myModules.keyboardGlitches.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable fixes for stuck keyboard presses in Proxmox VM";
    };
  };

  config = lib.mkIf config.myModules.keyboardGlitches.enable {
    # Disable USB autosuspend to prevent kernel from suspending input devices
    # When devices wake up from suspend, they can miss key release events
    # causing infinite key repetition
    boot.kernelParams = [ "usbcore.autosuspend=-1" ];

    # Disable powertop auto-tuning if enabled to prevent it from
    # auto-tuning keyboard power management
    powerManagement.powertop.enable = lib.mkForce false;

    # Adjust keyboard repeat settings to help prevent stuck keys
    # Shorter delay and interval reduces the window for stuck key issues
    services.xserver.autoRepeatDelay = lib.mkForce 200;  # ms (default: 500)
    services.xserver.autoRepeatInterval = lib.mkForce 25;  # ms (default: 30)

    # Note: If you're passing through USB controllers to the VM, this module
    # helps prevent USB device power management issues that cause the
    # keyboard to get stuck repeating keys.
  };
}
