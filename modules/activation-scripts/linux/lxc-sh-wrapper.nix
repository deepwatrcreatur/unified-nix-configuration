{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.linux.lxc-sh-wrapper;
  
  lxcShWrapperScript = pkgs.writeShellScript "lxc-sh-wrapper.sh" ''
    # Create /bin/sh wrapper for LXC containers
    rm -f /bin/sh
    cat > /bin/sh <<'EOF'
    #!/bin/bash
    export PATH=/run/current-system/sw/bin:/usr/bin:/bin
    exec /bin/bash "$@"
    EOF
    chmod +x /bin/sh
  '';
in
{
  options.custom.activation-scripts.linux.lxc-sh-wrapper = {
    enable = lib.mkEnableOption "LXC /bin/sh wrapper activation script";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.zzzBinShWrapper.text = lib.mkAfter ''
      echo "Running LXC /bin/sh wrapper script..."
      ${lxcShWrapperScript}
    '';
  };
}