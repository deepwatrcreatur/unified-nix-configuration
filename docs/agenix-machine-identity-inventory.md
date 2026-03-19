# Agenix Machine Identity Inventory

Copy these entries into Dashlane as secure notes or secrets. The private key
for each machine should live on the machine at `/var/lib/agenix/machine-identity`
with mode `0400` and owner `root:root`.

| Machine | Dashlane item | Runtime path | Public key file | Public key |
| --- | --- | --- | --- | --- |
| attic-cache | `agenix machine identity - attic-cache` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/attic-cache.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPT88sva3mAHz0ftQNHztNGOixadYzEHE+ZXoM7U+tbg agenix-machine-identity attic-cache` |
| gateway | `agenix machine identity - gateway` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/gateway.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEiXkvxAjZ/9d6l/uii4ZJxmxtqGMCDS4a/ufckCU+3A agenix-machine-identity gateway` |
| homeserver | `agenix machine identity - homeserver` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/homeserver.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1xgUz+rOhRweUPDB0+9MZbG1vJnr9cTFT/uuLVtsGy agenix-machine-identity homeserver` |
| pve-gateway | `agenix machine identity - pve-gateway` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-gateway.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJp9P0x51AN4U2K3T20806TPv8jHE7x/mNOVRFz5Cemx agenix-machine-identity pve-gateway` |
| pve-lattitude | `agenix machine identity - pve-lattitude` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-lattitude.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIILmDRTki5P8aLmYvX7aILAIEat++RUqphsM+IADWmNM agenix-machine-identity pve-lattitude` |
| pve-rog | `agenix machine identity - pve-rog` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-rog.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkWE8kICYI4rPsw/SWfEjOcBrKRk0DywrYSOFZkdlDX agenix-machine-identity pve-rog` |
| pve-strix | `agenix machine identity - pve-strix` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-strix.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzZpL56XGOHA7gOVeLNttiOYV/iNyoIOPAzwr5aONab agenix-machine-identity pve-strix` |
| pve-tomahawk | `agenix machine identity - pve-tomahawk` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/pve-tomahawk.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9TotDUuaBOyI8Tvm4PW1w8xf2RUUcg3g310HIxenyf agenix-machine-identity pve-tomahawk` |
| podman | `agenix machine identity - podman` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/podman.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCr6V3GOWCDJUKxnVAj+AZTUgGG7Vd51j/AQiMJ7SX1 agenix-machine-identity podman` |
| rustdesk | `agenix machine identity - rustdesk` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/rustdesk.pub` | `pending` |
| workstation | `agenix machine identity - workstation` | `/var/lib/agenix/machine-identity` | `ssh-keys/agenix-machine-identities/workstation.pub` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC22EvqG/w5v3w4TRwz4KajVwU5b19VXQJKbLKSQVlTy agenix-machine-identity workstation` |

Suggested generation command per machine:

```bash
install -d -m 700 /var/lib/agenix
ssh-keygen -t ed25519 -N '' -C "agenix-machine-identity $(hostname)" -f /var/lib/agenix/machine-identity
```

Suggested copy-back command:

```bash
ssh HOSTNAME 'cat /var/lib/agenix/machine-identity.pub' > ssh-keys/agenix-machine-identities/HOSTNAME.pub
```
