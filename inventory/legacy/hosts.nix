{
  attic-cache = {
    name = "attic-cache";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos-lxc/attic-cache;
    isDesktop = false;
    extraModules = [
      ../../hosts/nixos-lxc/lxc-systemd-suppressions.nix
      ../../hosts/nixos
    ];
  };

  gateway = {
    name = "gateway";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/gateway;
    isDesktop = false;
  };

  homeserver = {
    name = "homeserver";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos-lxc/homeserver;
    extraModules =
      [ ../../hosts/nixos/default.nix ]
      ++ (
        if builtins.pathExists /etc/nixos/local-secrets.nix then [ /etc/nixos/local-secrets.nix ] else [ ]
      );
  };

  inference1 = {
    name = "inference1";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference1;
  };

  inference2 = {
    name = "inference2";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference2;
  };

  inference3 = {
    name = "inference3";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference3;
  };

  inference-fresh = {
    name = "inference-fresh";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference-fresh;
  };

  podman = {
    name = "podman";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos-lxc/podman;
    isDesktop = false;
    extraModules = [
      ../../hosts/nixos-lxc/lxc-systemd-suppressions.nix
      ../../hosts/nixos
    ];
  };

  rustdesk = {
    name = "rustdesk";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos-lxc/rustdesk;
    isDesktop = false;
    extraModules = [
      ../../hosts/nixos-lxc/lxc-systemd-suppressions.nix
      ../../hosts/nixos
    ];
  };

  workstation = {
    name = "workstation";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/workstation;
    isDesktop = true;
    extraModules = [
      ../../hosts/nixos/default.nix
    ];
  };

  phoenix = {
    name = "phoenix";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/phoenix;
    isDesktop = true;
    extraModules = [
      ../../hosts/nixos/default.nix
    ];
  };
}
