# Agenix Machine Identities

Store dedicated public keys for machine-scoped agenix decryption here.

Naming convention:

- `{hostname}.pub`

Each file should contain the public half of the dedicated machine identity that
is copied onto the host at `/var/lib/agenix/machine-identity`.

These keys are separate from SSH host keys so rebuilt machines do not force
agenix rekeying.
