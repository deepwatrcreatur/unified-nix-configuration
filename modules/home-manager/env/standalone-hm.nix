# Imported by hosts that use Home Manager but are NOT NixOS
# (e.g., macOS, Proxmox with HM).
{ config, ... }:

{
  # This is critical for non-NixOS systems to find Nix packages.
  home.sessionPath = [ "${config.home.homeDirectory}/.nix-profile/bin" ];}
