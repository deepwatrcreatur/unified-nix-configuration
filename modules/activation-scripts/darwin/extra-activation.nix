{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.darwin.extra-activation;
  
  extraActivationScript = pkgs.writeShellScript "extra-activation.sh" ''
    # Set launchctl file descriptor limits
    echo "Setting launchctl file descriptor limits..."
    /bin/launchctl limit maxfiles 65536 200000 2>/dev/null || true
  '';
in
{
  options.custom.activation-scripts.darwin.extra-activation = {
    enable = lib.mkEnableOption "Extra activation script for macOS system limits";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.extraActivation.text = lib.mkAfter ''
      echo "Running extra activation script..."
      ${extraActivationScript}
    '';
  };
}