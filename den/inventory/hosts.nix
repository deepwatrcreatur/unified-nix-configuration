{
  authentik-host = {
    kind = "nixos";
    name = "authentik-host";
    system = "x86_64-linux";
    hostPath = ../hosts/authentik-host;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "lxc-core"
      "lxc-dhcp-networking"
      "attic-client"
      "nix-daemon-user-ssh"
      "home-manager-users"
    ];
  };

  attic-cache = {
    kind = "nixos";
    name = "attic-cache";
    system = "x86_64-linux";
    hostPath = ../hosts/attic-cache;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "attic-cache-core"
      "attic-cache-build-server"
      "attic-cache-home-manager"
    ];
  };

  gateway = {
    kind = "nixos";
    name = "gateway";
    system = "x86_64-linux";
    hostPath = ../hosts/gateway;
    isDesktop = false;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "gateway-router"
    ];
  };

  homeserver = {
    kind = "nixos";
    name = "homeserver";
    system = "x86_64-linux";
    hostPath = ../hosts/homeserver;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "lxc-core"
      "attic-client"
      "nix-daemon-user-ssh"
      "home-manager-users"
      "homeserver-networking"
      "homeserver-iperf3"
      "homeserver-homebridge"
      "homeserver-semaphore"
      "rustdesk-server"
    ];
  };

  router = {
    kind = "nixos";
    name = "router";
    system = "x86_64-linux";
    hostPath = ../hosts/router;
    isDesktop = false;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "router-router"
    ];
  };

  router-backup = {
    kind = "nixos";
    name = "router-backup";
    system = "x86_64-linux";
    hostPath = ../hosts/router-backup;
    isDesktop = false;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "router-router"
    ];
  };

  router-bootstrap = {
    kind = "nixos";
    name = "router-bootstrap";
    system = "x86_64-linux";
    hostPath = ../hosts/router-bootstrap;
    isDesktop = false;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "bootstrap-base"
    ];
  };

  inference1 = {
    kind = "nixos";
    name = "inference1";
    system = "x86_64-linux";
    hostPath = ../hosts/inference1;
    mode = "aspect";
    aspectsList = [
      "inference-vm-base"
      "inference-vm-nvidia"
      "inference1-ollama"
    ];
  };

  inference2 = {
    kind = "nixos";
    name = "inference2";
    system = "x86_64-linux";
    hostPath = ../hosts/inference2;
    mode = "aspect";
    aspectsList = [
      "inference-vm-base"
      "inference-vm-nvidia"
    ];
  };

  inference3 = {
    kind = "nixos";
    name = "inference3";
    system = "x86_64-linux";
    hostPath = ../hosts/inference3;
    mode = "aspect";
    aspectsList = [
      "inference-vm-base"
      "inference-vm-nvidia"
    ];
  };

  inference-fresh = {
    kind = "nixos";
    name = "inference-fresh";
    system = "x86_64-linux";
    hostPath = ../hosts/inference-fresh;
    mode = "aspect";
    aspectsList = [
      "inference-vm-base"
    ];
  };

  podman = {
    kind = "nixos";
    name = "podman";
    system = "x86_64-linux";
    hostPath = ../hosts/podman;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "lxc-core"
      "attic-client"
      "nix-daemon-user-ssh"
      "home-manager-users"
      "podman-lxc-suppressions"
      "podman-containers"
    ];
  };

  rustdesk = {
    kind = "nixos";
    name = "rustdesk";
    system = "x86_64-linux";
    hostPath = ../hosts/rustdesk;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "lxc-core"
      "attic-client"
      "nix-daemon-user-ssh"
      "home-manager-users"
      "rustdesk-server"
    ];
  };

  workstation = {
    kind = "nixos";
    name = "workstation";
    system = "x86_64-linux";
    hostPath = ../hosts/workstation;
    isDesktop = true;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "workstation-desktop"
    ];
  };

  phoenix = {
    kind = "nixos";
    name = "phoenix";
    system = "x86_64-linux";
    hostPath = ../hosts/phoenix;
    isDesktop = true;
    mode = "aspect";
    aspectsList = [
      "nixos-base"
      "workstation-desktop"
    ];
  };
}
