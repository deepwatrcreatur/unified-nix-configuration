# Agenix Machine Identity Inventory

Copy these entries into Dashlane as secure notes or secrets. The private key
for each machine should live on the machine at `/var/lib/agenix/machine-identity`
with mode `0400` and owner `root:root`.

| Machine | Dashlane item | Runtime path | Public key file | Public key |
| --- | --- | --- | --- | --- |
| attic-cache | `agenix machine identity - attic-cache` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/attic-cache.pub` | `TO_FILL` |
| gateway | `agenix machine identity - gateway` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/gateway.pub` | `TO_FILL` |
| homeserver | `agenix machine identity - homeserver` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/homeserver.pub` | `TO_FILL` |
| pve-gateway | `agenix machine identity - pve-gateway` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-gateway.pub` | `TO_FILL` |
| pve-lattitude | `agenix machine identity - pve-lattitude` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-lattitude.pub` | `TO_FILL` |
| pve-strix | `agenix machine identity - pve-strix` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-strix.pub` | `TO_FILL` |
| pve-tomahawk | `agenix machine identity - pve-tomahawk` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-tomahawk.pub` | `TO_FILL` |
| workstation | `agenix machine identity - workstation` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/workstation.pub` | `TO_FILL` |

Suggested generation command per machine:

```bash
install -d -m 700 /var/lib/agenix
ssh-keygen -t ed25519 -N '' -C "agenix-machine-identity $(hostname)" -f /var/lib/agenix/machine-identity
```

Suggested copy-back command:

```bash
ssh HOSTNAME 'cat /var/lib/agenix/machine-identity.pub' > ssh-keys/agenix-machine-identities/HOSTNAME.pub
```
