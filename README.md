I am combining nix configurations for different machines that were in separate repositories. Here is the planned structure:

```text
.
├── flake.nix
├── hosts/
│   ├── common-nixos.nix       # Settings truly common to ALL NixOS hosts
│   ├── nixos/                 # Directory for NixOS host configurations
│   │   ├── inference1/
│   │   │   ├── default.nix          # Tiny, sets hostname, imports common inference + hardware
│   │   │   ├── hardware-configuration.nix
│   │   │   └── arch.nix             # Optional: "x86_64-linux"
│   │   ├── inference2/
│   │   │   ├── default.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   └── arch.nix
│   │   ├── inference3/
│   │   │   ├── default.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   └── arch.nix
│   │   ├── homeserver/          # Your other NixOS host
│   │   │   ├── default.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   └── arch.nix
│   │   └── ...                  # Other NixOS hosts
│   └── darwin/                # For nix-darwin hosts (if you automate them too)
│       └── macminim4/
│           ├── default.nix
│           └── arch.nix             # "aarch64-darwin"
│
├── modules/
│   ├── nixos/
│   │   ├── common-inference-vm.nix # Shared settings for inference1,2,3
│   │   ├── homeAssistant.nix       # Example other shared module
│   │   └── ...
│   └── darwin/
│       └── ...
│
├── users/
│   └── deepwatrcreatur/
│       ├── common.nix
│       ├── inference1.nix # HM for inference1 (could be symlink if identical to others)
│       ├── inference2.nix
│       ├── inference3.nix
│       ├── homeserver.nix
│       └── macminim4.nix
│
└── ...
