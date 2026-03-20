# modules/nixos/lxc-common.nix
# Common configuration for all NixOS LXC containers
# Eliminates boilerplate across hosts/nixos-lxc/* hosts
{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

with lib;

let
  cfg = config.lxc;
in
{
  # Import LXC container module and required myModules at top level
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ./attic-client.nix        # Defines myModules.attic-client
    ./nix-daemon-user-ssh.nix # Defines myModules.nix-daemon-user-ssh
  ];

  options.lxc = {
    enable = mkEnableOption "LXC common configuration";

    users = {
      root = {
        enableFishShell = mkOption {
          type = types.bool;
          default = true;
          description = "Enable fish shell for root user";
        };
      };

      primaryUser = mkOption {
        type = types.str;
        default = "deepwatrcreatur";
        description = "Primary non-root user name";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ "wheel" ];
        example = [ "wheel" "podman" "docker" ];
        description = "Extra groups for the primary user";
      };

      enableNixbuilder = mkOption {
        type = types.bool;
        default = false;
        description = "Create nixbuilder system user for remote builds";
      };
    };

    homeManager = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable home-manager with LXC-compatible settings";
      };

      rootImports = mkOption {
        type = types.listOf types.deferredModule;
        default = [ ];
        description = "Additional imports for root's home-manager config";
      };

      rootPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional packages for root user";
      };

      primaryUserImports = mkOption {
        type = types.listOf types.deferredModule;
        default = [ ];
        description = "Additional imports for primary user's home-manager config";
      };
    };

    networking = {
      useDHCP = mkOption {
        type = types.bool;
        default = true;
        description = "Use DHCP for networking (static lease configured in DNS server)";
      };

      staticIP = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10.10.10.71";
        description = "Static IP address (if not using DHCP)";
      };

      gateway = mkOption {
        type = types.str;
        default = "10.10.10.1";
        description = "Default gateway";
      };

      nameservers = mkOption {
        type = types.listOf types.str;
        default = [ "10.10.10.1" ];
        description = "DNS nameservers";
      };
    };

    services = {
      atticClient = mkOption {
        type = types.bool;
        default = false;
        description = "Enable attic binary cache client";
      };

      sshKeysManager = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SSH keys manager for automatic authorized_keys deployment";
      };

      nixDaemonUserSsh = mkOption {
        type = types.bool;
        default = false;
        description = "Enable nix-daemon to use user's SSH socket for git+ssh flake inputs";
      };
    };

    agenix = {
      machineIdentity = mkOption {
        type = types.bool;
        default = false;
        description = "Use stable per-host agenix identity";
      };

      atticToken = mkOption {
        type = types.bool;
        default = false;
        description = "Include attic-client-token secret";
      };
    };
  };

  config = mkIf cfg.enable {
    # Mark as LXC container
    host.type = mkDefault "lxc";
    host.networking.enableTailscale = mkDefault false; # LXC can't run Tailscale

    # Fish shell for all users
    programs.fish.enable = true;

    # SSH server
    services.openssh = {
      enable = mkDefault true;
      settings = {
        PermitRootLogin = mkDefault "yes";
      };
    };

    # Sudo configuration
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    security.wrappers.sudo.setuid = true;

    # Common systemd mount suppressions for LXC
    systemd.mounts = [
      {
        what = "debugfs";
        where = "/sys/kernel/debug";
        enable = false;
      }
    ];

    # Networking
    networking.useDHCP = cfg.networking.useDHCP;
    networking.interfaces.eth0.ipv4.addresses = mkIf (cfg.networking.staticIP != null) [
      {
        address = cfg.networking.staticIP;
        prefixLength = 16;
      }
    ];
    networking.defaultGateway = mkIf (cfg.networking.staticIP != null) cfg.networking.gateway;
    networking.nameservers = mkIf (cfg.networking.staticIP != null) cfg.networking.nameservers;

    # Root user
    users.users.root.shell = mkIf cfg.users.root.enableFishShell pkgs.fish;

    # Primary user
    users.users.${cfg.users.primaryUser} = {
      isNormalUser = true;
      extraGroups = cfg.users.extraGroups;
      shell = pkgs.fish;
    };

    # Nixbuilder user for remote builds
    users.users.nixbuilder = mkIf cfg.users.enableNixbuilder {
      isSystemUser = true;
      group = "nixbuilder";
      home = "/var/lib/nixbuilder";
      createHome = true;
      shell = pkgs.bash;
    };
    users.groups.nixbuilder = mkIf cfg.users.enableNixbuilder { };

    # SSH keys manager
    services.ssh-keys-manager.username = mkIf cfg.services.sshKeysManager cfg.users.primaryUser;

    # Attic client
    myModules.attic-client.enable = mkIf cfg.services.atticClient true;

    # Nix daemon SSH socket
    myModules.nix-daemon-user-ssh.enable = mkIf cfg.services.nixDaemonUserSsh true;

    # Agenix
    my.agenix.machineIdentity.enable = mkIf cfg.agenix.machineIdentity true;
    age.secrets."attic-client-token" = mkIf cfg.agenix.atticToken {
      file = ../../secrets-agenix/attic-client-token.age;
      path = "/run/secrets/attic-client-token";
      owner = "root";
      mode = "0400";
    };

    # Home-manager configuration with LXC fix
    systemd.services."home-manager-root".environment.NIX_REMOTE = mkIf cfg.homeManager.enable "daemon";
    systemd.services."home-manager-${cfg.users.primaryUser}".environment.NIX_REMOTE = mkIf cfg.homeManager.enable "daemon";

    home-manager = mkIf cfg.homeManager.enable {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };

      users.root = {
        imports = [
          ../../users/root
        ] ++ cfg.homeManager.rootImports;

        home.username = "root";
        home.homeDirectory = "/root";
        home.stateVersion = mkDefault "25.11";
        programs.home-manager.enable = true;
        home.packages = cfg.homeManager.rootPackages;
      };

      users.${cfg.users.primaryUser} = {
        imports = cfg.homeManager.primaryUserImports;

        home.username = cfg.users.primaryUser;
        home.homeDirectory = "/home/${cfg.users.primaryUser}";
        home.stateVersion = mkDefault "25.11";
        programs.home-manager.enable = true;
      };
    };

    system.stateVersion = mkDefault "25.05";
  };
}
