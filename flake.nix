# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.inputs.flake-utils.follows = "flake-utils";

    flake-utils.url = "github:numtide/flake-utils";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # LLM/AI coding agents - comprehensive package set from numtide
    # NOTE: intentionally NOT following nixpkgs so derivation hashes match
    # the garnix.io binary cache (cache.garnix.io), avoiding local compilation
    llm-agents.url = "github:numtide/llm-agents.nix";

    # RTK hook integration for AI coding agents
    nix-rtk = {
      url = "github:deepwatrcreatur/nix-rtk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.llm-agents.follows = "llm-agents";
    };

    nixbit = {
      url = "github:pbek/nixbit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-whitesur-config = {
      url = "github:deepwatrcreatur/nix-whitesur-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-linuxbrew = {
      url = "github:deepwatrcreatur/nix-linuxbrew/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tesla-inference-flake = {
      url = "github:deepwatrcreatur/tesla-inference-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fnox = {
      url = "github:deepwatrcreatur/fnox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    qmd = {
      url = "github:tobi/qmd";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    zellij-vivid-rounded = {
      url = "github:deepwatrcreatur/nix-zellij-vivid-rounded";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gnome-cosmic-ui = {
      url = "github:deepwatrcreatur/nix-gnome-cosmic-ui";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nix-attic-infra = {
      url = "github:deepwatrcreatur/nix-attic-infra/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    ssh-keys-manager = {
      url = "github:deepwatrcreatur/nix-ssh-keys-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-router-optimized = {
      url = "github:deepwatrcreatur/nix-router-optimized";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-authentik = {
      url = "github:deepwatrcreatur/nix-authentik";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dmux-flake = {
      url = "github:deepwatrcreatur/nix-dmux"; # Your new dmux package flake
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr - terminal-native agent multiplexer, pinned to an upstream release tag.
    herdr.url = "github:ogulcancelik/herdr/v0.6.2";

    agents-status-tray-home-manager = {
      url = "github:deepwatrcreatur/agents-status-tray-home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    cosmic-applet-proxmoxbar = {
      url = "github:deepwatrcreatur/cosmic-applet-proxmoxbar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cosmic-applet-agents-status = {
      url = "github:deepwatrcreatur/cosmic-applet-agents-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-semaphore = {
      url = "github:deepwatrcreatur/nix-semaphore";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-lightpanda = {
      url = "github:deepwatrcreatur/nix-lightpanda";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-markit = {
      url = "github:deepwatrcreatur/nix-markit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-roundtable = {
      url = "github:deepwatrcreatur/agent-roundtable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # beads_rust upstream package; the repo wraps it as `beads-rust` to avoid
    # colliding with the Homebrew viewer's `br` command.
    beads-rust = {
      url = "github:Dicklesworthstone/beads_rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      flakeLib = import ./lib/flake {
        inherit inputs;
        repoRoot = ./.;
      };
    in
    (flakeLib.loadOutputs ./outputs)
    // {
      homeConfigurations.hm-opts = flakeLib.helpers.mkHomeConfig {
        targetSystem = "x86_64-linux";
        hostName = "";
        userPath = ./modules/home-manager/non-nixos.nix;
        modules = [
          {
            home.username = "hm-opts";
            home.homeDirectory = "/tmp/hm-opts";
            home.stateVersion = "26.05";
          }
        ];
      };
    };
}
