
{ config, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all";
      right_format = "$time";
    };
  };
}
