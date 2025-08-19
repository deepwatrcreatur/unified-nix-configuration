{ config, lib, pkgs, inputs, ... }:

{

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;  
    enableNushellIntegration = true; 
  };
}
