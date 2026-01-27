# modules/home-manager/whatsapp-alternatives.nix - WhatsApp desktop client alternatives
{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.myModules.whatsappAlternatives = {
    enable = lib.mkEnableOption "Enable WhatsApp desktop alternatives";
    
    client = lib.mkOption {
      type = lib.types.enum [ "whatsapp-for-linux" "zapzap" "whatsapp-electron" ];
      default = "whatsapp-for-linux";
      description = "Which WhatsApp client to use";
    };
  };

  config = lib.mkIf config.myModules.whatsappAlternatives.enable {
    home.packages = with pkgs; 
      if config.myModules.whatsappAlternatives.client == "whatsapp-for-linux" then
        [ whatsapp-for-linux ]
      else if config.myModules.whatsappAlternatives.client == "zapzap" then
        [ zapzap ]
      else if config.myModules.whatsappAlternatives.client == "whatsapp-electron" then
        [ whatsapp ]
      else [];
  };
}