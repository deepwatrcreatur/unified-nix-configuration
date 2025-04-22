I am combining nix configurations for different machines that were in separate repositories.

*   `.`
    *   `flake.nix`
    *   `flake.lock`
    *   `hosts/`
        *   `common.nix` # Settings shared by both hosts
        *   `inference1/`
            *   `default.nix`
            *   `hardware-configuration.nix`
            *   `home.nix`
        *   `homeserver/`
            *   `default.nix` # homeserver specific system settings
            *   `lxc-container.nix`
    *   `modules/`
        *   `nixos/`
            *   `homeAssistant.nix`
    *   `secrets/` # Encrypted secrets
        *   `secrets.yaml` # Default sops file
        *   `reolink-secrets.yaml` # inclined to keep these in other cloud storage
        *   `influxdb-secrets.yaml`
        *   `age-key.txt` # NOT committed to Git
    *   `dotfiles/`
        *   `.bashrc`
        *   `.inputrc`
        *   `.gitconfig`
        *   `...`
    *   `.gitignore`
    *   `README.md`
