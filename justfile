# justfile — repo-wide operations
# Host-specific rebuilds live in users/{user}/hosts/{host}/justfile
#
# nixos-anywhere bootstrap workflow:
#   1. just gen-identity <host>           # generate stable machine identity
#   2. Edit secrets.nix — add <host> to relevant recipient groups
#   3. just rekey                          # re-encrypt secrets for new recipient
#   4. just install <host> <target-ip>     # install NixOS, agenix works on first boot

agenix_url        := "github:ryantm/agenix"
nixos_anywhere_url := "github:nix-community/nixos-anywhere"

# ---------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------

# Re-encrypt all agenix secrets after editing secrets.nix
rekey dir=`pwd`:
    nix run {{agenix_url}} -- -r --rules "{{dir}}/secrets.nix"

# ---------------------------------------------------------------------------
# nixos-anywhere bootstrap
# ---------------------------------------------------------------------------

# Step 1 — generate a stable machine identity for a new host.
# Writes the public key to ssh-keys/agenix-machine-identities/<host>.pub
# and keeps the private key at /tmp/nix-bootstrap-<host>/machine-identity
# for use by 'just install'.
gen-identity host dir=`pwd`:
    #!/usr/bin/env bash
    set -euo pipefail
    pubkey_dst="{{dir}}/ssh-keys/agenix-machine-identities/{{host}}.pub"
    keydir="/tmp/nix-bootstrap-{{host}}"

    if [ -f "$pubkey_dst" ]; then
        echo "Identity already exists: $pubkey_dst"
        exit 0
    fi

    install -d -m 700 "$keydir"
    install -d -m 755 "$(dirname "$pubkey_dst")"
    ssh-keygen -t ed25519 -N '' \
        -C "agenix-machine-identity {{host}}" \
        -f "$keydir/machine-identity"
    chmod 400 "$keydir/machine-identity"
    cp "$keydir/machine-identity.pub" "$pubkey_dst"

    echo ""
    echo "  public key  → $pubkey_dst"
    echo "  private key → $keydir/machine-identity  ⚠ delete after install"
    echo ""
    echo "Next steps:"
    echo "  1. Add {{host}} to the appropriate recipient groups in secrets.nix"
    echo "  2. just rekey"
    echo "  3. just install {{host}} <target-ip>"
    echo "  4. just clean-identity {{host}}  # remove private key from /tmp"

# Step 3 — install NixOS on a new host via nixos-anywhere.
# Seeds the machine identity into the installed system via --extra-files so
# agenix can decrypt secrets on first boot without a second rebuild pass.
#
# Prerequisites: gen-identity done, secrets.nix updated, rekey done.
#
# Optional parameters:
#   hw          path for auto-generated hardware-configuration.nix (empty = skip)
#   disk        disko disk device path, e.g. /dev/disk/by-id/...  (empty = skip)
#   accept_new  set to "true" to pass StrictHostKeyChecking=accept-new (TOFU —
#               only use when you cannot pre-verify the installer host key)
#
# Example:
#   just install gateway 10.10.10.1
#   just install inference1 10.10.11.131 accept_new=true \
#       hw=hosts/nixos/inference-vm/hosts/inference1/hardware-configuration.nix \
#       disk=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0
install host target hw="" disk="" accept_new="" dir=`pwd`:
    #!/usr/bin/env bash
    set -euo pipefail
    keydir="/tmp/nix-bootstrap-{{host}}"
    pubkey="{{dir}}/ssh-keys/agenix-machine-identities/{{host}}.pub"

    if [ ! -f "$keydir/machine-identity" ]; then
        echo "Error: no identity at $keydir/machine-identity"
        echo "Run: just gen-identity {{host}}"
        exit 1
    fi
    if [ ! -f "$pubkey" ]; then
        echo "Error: no public key at $pubkey"
        echo "Run: just gen-identity {{host}}"
        exit 1
    fi
    if [ -n "{{hw}}" ] && [ ! -f "{{dir}}/{{hw}}" ]; then
        echo "Error: hw path not found: {{dir}}/{{hw}}"
        exit 1
    fi

    # Build the extra-files tree that nixos-anywhere merges into the new system
    extra="$(mktemp -d)"
    trap 'rm -rf "$extra"' EXIT

    install -d -m 700 "$extra/var/lib/agenix"
    install -m 400 "$keydir/machine-identity"     "$extra/var/lib/agenix/machine-identity"
    install -m 644 "$keydir/machine-identity.pub" "$extra/var/lib/agenix/machine-identity.pub"

    # Build the nixos-anywhere command
    cmd=(
        nix run {{nixos_anywhere_url}} --
        --extra-files "$extra"
        --flake "{{dir}}#{{host}}"
    )

    # TOFU opt-in: only skip host key verification when explicitly requested.
    # To pre-verify instead: ssh-keyscan <target> >> ~/.ssh/known_hosts
    if [ "{{accept_new}}" = "true" ]; then
        cmd+=(--ssh-option StrictHostKeyChecking=accept-new)
    fi

    if [ -n "{{hw}}" ]; then
        cmd+=(--generate-hardware-config nixos-generate-config "{{dir}}/{{hw}}")
    fi
    if [ -n "{{disk}}" ]; then
        cmd+=(--disk main "{{disk}}")
    fi

    cmd+=(root@{{target}})

    "${cmd[@]}"

    # Private key no longer needed locally — the installed system has its copy
    rm -rf "$keydir"
    echo ""
    echo "Install complete. Private key removed from $keydir."
    echo ""
    echo "Review and commit before next rebuild:"
    git -C "{{dir}}" status --short \
        "ssh-keys/agenix-machine-identities/{{host}}.pub" \
        "secrets-agenix/"

# Remove a host's temporary private key from /tmp if install was interrupted.
# Under normal circumstances 'just install' cleans up automatically.
clean-identity host:
    #!/usr/bin/env bash
    keydir="/tmp/nix-bootstrap-{{host}}"
    if [ -d "$keydir" ]; then
        rm -rf "$keydir"
        echo "Removed $keydir"
    else
        echo "Nothing to clean for {{host}}"
    fi
