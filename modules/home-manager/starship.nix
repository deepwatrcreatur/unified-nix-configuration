# modules/home-manager/starship.nix
{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = false;
      format = "$all";
      right_format = "$time";

      directory = {
        truncation_length = 1;
        truncate_to_repo = true; # A useful related setting
      };
    };
  };
}
