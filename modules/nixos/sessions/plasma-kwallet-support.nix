{ pkgs, ... }:

{
  # Plasma already brings KWallet; wire the display-manager PAM services so
  # password logins unlock the wallet and autologin follows the same path when
  # possible.
  security.pam.services = {
    sddm.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };

    sddm-autologin.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
  };

  environment.systemPackages = with pkgs; [
    libsecret
  ];
}
