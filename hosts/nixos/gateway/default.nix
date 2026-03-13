{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/common
    ../../../modules/common/utility-packages.nix
    ../../../modules/nixos/keyboard-glitches.nix # Fix stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/activation-scripts
    inputs.agenix.nixosModules.default # Agenix secrets management
    # Import only specific modules, NOT default (which includes nftables-fasttrack that conflicts with our nftables.nix)
    inputs.nix-router-optimized.nixosModules.router-optimizations
    inputs.nix-router-optimized.nixosModules.router-dashboard
    inputs.nix-router-optimized.nixosModules.dns-zone
    ./nftables.nix # NFtables firewall configuration
    ./networking.nix # Network interface configuration
  ];

  # Router optimizations (hardware offload, fasttrack, queue management)
  services.router-optimizations = {
    enable = true;
    interfaces = {
      wan = {
        device = "ens17";
        role = "wan";
        label = "WAN";
        bandwidth = "1Gbit";
      };
      lan = {
        device = "ens16";
        role = "lan";
        label = "LAN";
      };
      management = {
        device = "ens18";
        role = "management";
        label = "Management";
      };
    };
    conntrack-max = 262144;
  };

  # Router dashboard configuration
  services.router-dashboard = {
    enable = true;
    port = 8888;
    interfaces = [
      { device = "ens16"; label = "LAN"; role = "lan"; }
      { device = "ens17"; label = "WAN"; role = "wan"; }
      { device = "ens18"; label = "Management"; role = "mgmt"; }
    ];
  };

  # DNS zone management with static hosts imported from external file.
  # Edit ./dns-zone.nix to manage one or more zones.
  services.router.dnsZones = let
    dnsConfig = import ./dns-zone.nix;
    defaultNetworks = [
      "10.10.10.0/24"
      "10.10.11.0/24"
    ];
    mkZone = zone: {
      nameserverIP = zone.nameserverIP or "10.10.10.1";
      allowDynamicUpdates = zone.allowDynamicUpdates or true;
      aliases = zone.aliases or {};
      staticHosts = lib.mapAttrs (_name: host: {
        ipAddress = host.ipv4;
        aliases = host.aliases or [];
      }) zone.hosts;
      reverseZone = {
        enable = zone.reverseZone.enable or true;
        networks = zone.reverseZone.networks or defaultNetworks;
      };
    };
  in
    if dnsConfig ? zones then
      lib.mapAttrs (_zoneName: zone: mkZone zone) dnsConfig.zones
    else
      {
        "${dnsConfig.domain}" = mkZone dnsConfig;
      };

  # Caddy reverse proxy with Let's Encrypt
  services.caddy = {
    enable = true;
    email = "deepwatrcreatur@gmail.com";
    
    virtualHosts."deepwatercreature.com" = {
      extraConfig = ''
        # Reverse proxy configuration
        handle {
          respond "Welcome to deepwatercreature.com"
        }
      '';
    };
    
    virtualHosts."*.deepwatercreature.com" = {
      extraConfig = ''
        # Wildcard subdomain handling
        respond "Subdomain of deepwatercreature.com"
      '';
    };
  };

  # Enable remote building on gateway using attic-cache
  nix.distributedBuilds = lib.mkForce true;
  nix.buildMachines = lib.mkForce [
    {
      hostName = "10.10.11.39"; # attic-cache
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      sshUser = "root";
      sshKey = "/root/.ssh/id_ed25519"; # Use existing gateway root SSH key
    }
  ];

  # Home manager configuration for gateway
  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../modules/home-manager/git.nix
      ../../../modules/home-manager/gpg-cli.nix
      ../../../users/deepwatrcreatur/hosts/gateway
    ];
    
    home.username = "deepwatrcreatur";
    home.homeDirectory = "/home/deepwatrcreatur";
    programs.home-manager.enable = true;
  };

  home-manager.extraSpecialArgs.hostName = "gateway";
  home-manager.extraSpecialArgs.isDesktop = false;

  # Boot loader (GRUB for MBR/BIOS)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";  # Install GRUB on the disk
  boot.loader.timeout = 5;
  boot.growPartition = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Technitium DNS & DHCP Server
  services.technitium-dns-server.enable = true;
  
  # Disable custom logging for Technitium - use default state directory
  # The spinning disk logging causes read-only filesystem errors with DynamicUser
  # systemd.services.technitium-dns-server = {
  #   environment = {
  #     TECHNITIUM_DNS_LOG_FOLDER = "/var/log/gateway/technitium";
  #   };
  #   serviceConfig = {
  #     ReadWritePaths = [ "/var/log/gateway/technitium" ];
  #   };
  # };
  
  # Configure systemd journal to use spinning disk
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=2G
    RuntimeMaxUse=100M
  '';
  
  # Bind mount journal to spinning disk
  fileSystems."/var/log/journal" = {
    device = "/var/log/gateway/journal";
    fsType = "none";
    options = [ "bind" "nofail" "x-systemd.automount" ];
    depends = [ "/var/log/gateway" ];
  };
  
  # Enable podman for containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";
  
  # QEMU guest agent for Proxmox
  services.qemuGuest.enable = true;

  # SSH daemon
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password"; # Secure default
    extraConfig = ''
      Match Address 10.10.10.0/24
        PermitRootLogin yes
    '';
  };
  
  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "10.10.0.0/16"  # LAN network
    ];
  };

  # Define your user account (SSH keys managed by common/ssh-keys.nix)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  # Enable fish shell
  programs.fish.enable = true;
  
  # Allow wheel group to use sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Mount the 10GB spinning disk for all log files to preserve SSD lifespan
  fileSystems."/var/log/gateway" = {
    device = "/dev/disk/by-uuid/f4b71c97-3f7f-47b3-a644-d82e051d5343";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.automount" ];
    neededForBoot = false;
  };

  # Systemd service to set up log directory structure on HDD
  systemd.services.setup-gateway-logs = {
    description = "Set up gateway log directories on spinning disk";
    after = [ "var-log-gateway.mount" ];
    wants = [ "var-log-gateway.mount" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Create log directories if they don't exist
      mkdir -p /var/log/gateway/system
      mkdir -p /var/log/gateway/technitium
      mkdir -p /var/log/gateway/journal
      
      # Set proper permissions
      chmod 755 /var/log/gateway/system
      chmod 777 /var/log/gateway/technitium  # World-writable for DynamicUser
      chmod 755 /var/log/gateway/journal
      
      echo "Gateway log directories created on spinning disk"
    '';
  };

  # Tmpfiles rules for additional log management
  systemd.tmpfiles.rules = [
    # Create additional service log directories on HDD
    "d /var/log/gateway/system 0755 root root -"
    "d /var/log/gateway/technitium 0777 root root -"  # World-writable for DynamicUser
    "d /var/log/gateway/journal 0755 root root -"
    "d /var/log/gateway/prometheus 0755 prometheus prometheus -"
    "d /var/log/gateway/grafana 0755 grafana grafana -"
  ];

  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Agenix configuration
  age.secrets.technitium-api-key = {
    file = ../../../secrets-agenix/technitium-api-key.age;
    owner = "root";
    group = "root";
    mode = "0444";  # World-readable for router-dashboard DynamicUser access
  };
  
  environment.variables.TECHNITIUM_API_KEY_FILE = config.age.secrets.technitium-api-key.path;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
