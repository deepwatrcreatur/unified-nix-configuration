{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.darwin.post-activation;
  
  postActivationScript = pkgs.writeShellScript "post-activation.sh" ''
    # Disable automatic software updates
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
  '';
in
{
  options.custom.activation-scripts.darwin.post-activation = {
    enable = lib.mkEnableOption "Post-activation script for macOS";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "Running post-activation script..."
      ${postActivationScript}
    '';
  };
}