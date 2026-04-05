{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  atticCache = import ../../../../lib/attic-cache.nix;
in
{
  imports = [
    ./justfile.nix
    ./nh.nix
    ./proxmox-shell-extra.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
    # Selectively import only essential modules to avoid activation issues
    ../../../../modules/home-manager/user-secrets.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
    ../../../../modules/home-manager/common/nix-user-config.nix
    ../../../../modules/home-manager/common/attic-client.nix
    ../../../../modules/home-manager/common/fish.nix
    ../../../../modules/home-manager/common/starship.nix
    ../../../../modules/home-manager/common/atuin.nix
    ../../../../modules/home-manager/common/fnox.nix
    ../../../../modules/home-manager/common/bat.nix
    ../../../../modules/home-manager/common/tool-aliases.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  nix.package = pkgs.nix;

  home.packages = with pkgs; [
    proxmenux
  ];
  # Determinate Nix manages `/etc/nix/nix.conf`; we only add user extras.
  services.nix-user-config = {
    enable = true;
    netrcMachine = null;
    substituters = atticCache.defaultSubstituters { includeNixCi = true; };
    trustedPublicKeys = atticCache.defaultTrustedPublicKeys { includeNixCi = true; };
    netrcEntries = [
      {
        machine = atticCache.serverName;
        passwordPath = "${config.home.homeDirectory}/.config/sops/attic-client-token";
        fnoxSecretName = "ATTIC_CLIENT_JWT_TOKEN";
      }
    ];
    netrcSnippetPaths = [
      "${config.home.homeDirectory}/.config/nix/nix-ci-netrc"
    ];
  };

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  # Enable attic-client for binary cache access
  programs.attic-client.enable = true;

  # Prefer system or future agenix-provided tokens while keeping the existing
  # root SOPS secrets path as a compatibility fallback on Debian/Proxmox hosts.
  services.user-secrets = {
    enable = true;
    secretsPath = ../../secrets;
  };

  # Decrypt agenix user secrets using the stable machine identity on the proxmox host
  services.agenix-user-secrets = {
    enable = true;
    identityFile = "/var/lib/agenix/machine-identity";
    secrets = {
      github-token = {
        source = ../../../../secrets-agenix/github-token.age;
        target = ".local/share/agenix-user-secrets/github-token";
        extraTargets = [".config/git/github-token"];
      };
      nix-ci-netrc = {
        source = ../../../../secrets-agenix/nix-ci-netrc.age;
        target = ".local/share/agenix-user-secrets/nix-ci-netrc";
        extraTargets = [".config/nix/nix-ci-netrc"];
      };
      nix-remote-builder-key = {
        source = ../../../../secrets-agenix/nix-remote-builder-key.age;
        target = ".local/share/agenix-user-secrets/nix-remote-builder-key";
        extraTargets = [".ssh/nix-remote"];
      };
    };
  };

  # Remote building configuration - offload builds to attic-cache
  home.activation.setupRemoteBuilder = lib.hm.dag.entryAfter ["agenixUserSecrets"] ''
    # Create /etc/nix/machines with remote builder config
    machines_file="/etc/nix/machines"
    machines_content="ssh://deepwatrcreatur@10.10.11.39 x86_64-linux /root/.ssh/nix-remote 8 2 nixos-test,benchmark,big-parallel,kvm - -"

    if [[ ! -f "$machines_file" ]] || ! grep -qF "10.10.11.39" "$machines_file" 2>/dev/null; then
      echo "$machines_content" | tee "$machines_file" > /dev/null
      chmod 644 "$machines_file"
      echo "Configured remote builder in $machines_file"
    fi

    # Ensure SSH key permissions
    if [[ -f "$HOME/.ssh/nix-remote" ]]; then
      chmod 600 "$HOME/.ssh/nix-remote"
    fi
  '';
}
