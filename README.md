I am combining nix configurations for different machines that were in separate repositories.
*   `.`
    *   `flake.nix`
    *   `flake.lock`
    *   `hosts/`
        *   `common.nix`&nbsp;&nbsp;&nbsp;&nbsp;# Settings shared by both hosts
        *   `inference1/`
            *   `default.nix`
            *   `hardware-configuration.nix`
            *   `home.nix`
        *   `homeserver/`
            *   `default.nix`&nbsp;&nbsp;&nbsp;&nbsp;# homeserver specific system settings
            *   `lxc-container.nix`
    *   `modules/`
        *   `nixos/`
            *   `homeAssistant.nix`
    *   `secrets/`&nbsp;&nbsp;&nbsp;&nbsp;# Encrypted secrets
        *   `secrets.yaml`&nbsp;&nbsp;&nbsp;&nbsp;# Default sops file
        *   `reolink-secrets.yaml`&nbsp;&nbsp;&nbsp;&nbsp;# inclined to keep these in other cloud storage
        *   `influxdb-secrets.yaml`
        *   `age-key.txt`&nbsp;&nbsp;&nbsp;&nbsp;# NOT committed to Git
    *   `dotfiles/`
        *   `.bashrc`
        *   `.inputrc`
        *   `.gitconfig`
        *   `...`
    *   `.gitignore`
    *   `README.md`
