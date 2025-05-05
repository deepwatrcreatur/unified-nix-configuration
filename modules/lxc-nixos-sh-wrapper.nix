{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  system.activationScripts.zzzBinShWrapper.text = ''
    rm -f /bin/sh
    cat > /bin/sh <<'EOF'
  #!/run/current-system/sw/bin/bash
  export PATH=/run/current-system/sw/bin:/usr/bin:/bin
  exec /run/current-system/sw/bin/bash "$@"
  EOF
    chmod +x /bin/sh
  '';
}
