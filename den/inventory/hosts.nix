{
  attic-cache = {
    kind = "nixos";
    name = "attic-cache";
    system = "x86_64-linux";
    hostPath = ../hosts/attic-cache;
    mode = "aspect";
  };

  gateway = {
    kind = "nixos";
    name = "gateway";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/gateway;
    isDesktop = false;
    mode = "legacy";
  };

  homeserver = {
    kind = "nixos";
    name = "homeserver";
    system = "x86_64-linux";
    hostPath = ../hosts/homeserver;
    mode = "aspect";
  };

  inference1 = {
    kind = "nixos";
    name = "inference1";
    system = "x86_64-linux";
    hostPath = ../hosts/inference1;
    mode = "aspect";
  };

  inference2 = {
    kind = "nixos";
    name = "inference2";
    system = "x86_64-linux";
    hostPath = ../hosts/inference2;
    mode = "aspect";
  };

  inference3 = {
    kind = "nixos";
    name = "inference3";
    system = "x86_64-linux";
    hostPath = ../hosts/inference3;
    mode = "aspect";
  };

  inference-fresh = {
    kind = "nixos";
    name = "inference-fresh";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference-fresh;
    mode = "legacy";
  };

  podman = {
    kind = "nixos";
    name = "podman";
    system = "x86_64-linux";
    hostPath = ../hosts/podman;
    mode = "aspect";
  };

  rustdesk = {
    kind = "nixos";
    name = "rustdesk";
    system = "x86_64-linux";
    hostPath = ../hosts/rustdesk;
    mode = "aspect";
  };

  workstation = {
    kind = "nixos";
    name = "workstation";
    system = "x86_64-linux";
    hostPath = ../hosts/workstation;
    isDesktop = true;
    mode = "aspect";
  };

  phoenix = {
    kind = "nixos";
    name = "phoenix";
    system = "x86_64-linux";
    hostPath = ../hosts/phoenix;
    isDesktop = true;
    mode = "aspect";
  };
}
