# Agenix Machine Identities

Store dedicated public keys for machine-scoped agenix decryption here.

Naming convention:

- `{hostname}.pub`

Each file should contain the public half of the dedicated machine identity that
stays in this repository as `ssh-keys/agenix-machine-identities/{hostname}.pub`.

The private half lives only on the host at `/var/lib/agenix/machine-identity`.
Do not copy the repository `.pub` file to that private-key path.

These keys are separate from SSH host keys so rebuilt machines do not force
agenix rekeying.
