{ config, pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    package = pkgs.rbw;
    settings = {
      email = "bitwarden.com@deepwatercreature.com";
      lock_timeout = 300; # Cache login info for 5 minutes
      # pinentry = pkgs.pinentry-gtk2; # Specify pinentry program (optional)
      # base_url = "https://bitwarden.example.com/"; # For self-hosted (optional)
      # identity_url = "https://identity.example.com/"; # For self-hosted (optional)
    };
  };
}
