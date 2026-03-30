{
  lib,
  pkgs,
  ...
}:

let
  deepwatrcreaturStableKey = lib.strings.trim (
    builtins.readFile ../../../ssh-keys/deepwatrcreatur-stable-identity.pub
  );
  rootStableKey = lib.strings.trim (builtins.readFile ../../../ssh-keys/root-stable-identity.pub);
in
{
  imports = [
    ../../common/nix-settings.nix
    ../common/nix-ci-netrc.nix
    ../snapper.nix
  ];

  # Keep bootstrap installs on the public/local caches only.
  myModules.caches.enableAttic = lib.mkDefault true;
  myModules.caches.enableNixCi = lib.mkDefault false;

  programs.ssh.startAgent = false;

  environment.systemPackages = lib.mkForce (
    with pkgs;
    [
      attic-client
      btrfs-progs
      curl
      git
      just
      snapper
      tmux
    ]
  );

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [
      "networkmanager"
      "snapper"
      "wheel"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ deepwatrcreaturStableKey ];
  };

  users.users.root = {
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [ rootStableKey ];
  };

  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  boot = {
    growPartition = true;
    loader = {
      systemd-boot.enable = lib.mkForce false;
      limine.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "console=ttyS0,115200" ];
  };

  systemd.services."serial-getty@ttyS0".enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Bootstrap images need the builder configuration even before any host-specific
  # agenix secrets exist. The key can be seeded manually at /root/.ssh/nix-remote.
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "10.10.11.39";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      sshUser = "deepwatrcreatur";
      sshKey = "/root/.ssh/nix-remote";
    }
  ];

  programs.ssh.extraConfig = ''
    Host attic-cache 10.10.11.39
      User deepwatrcreatur
      IdentityFile /root/.ssh/nix-remote
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';

  system.stateVersion = "25.11";
}
