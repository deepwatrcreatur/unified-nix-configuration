{ pkgs, ... }:

{
  # Use the native GNOME Keyring integration path so display-manager PAM can
  # unlock it instead of managing an extra ad hoc user service.
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    libsecret
  ];
}
