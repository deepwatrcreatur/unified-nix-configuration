# Inference VM shared models storage with VirtioFS

This document captures the current design and host/guest steps for sharing Ollama models across inference VMs using VirtioFS from Proxmox.

## Goals

- Single shared models store for `inference1`–`inference3`.
- Backed by ZFS on the Proxmox host (later Ceph), but stable for NixOS guests.
- Minimal NixOS magic: treat VirtioFS like a normal filesystem; permissions are enforced on the host.

## Proxmox host (pve-tomahawk)

### 1. Create ZFS dataset for models

On `pve-tomahawk`:

```sh
zfs create -o mountpoint=/rpool/inference-models rpool/inference-models
zfs set refquota=300G rpool/inference-models   # or whatever size you want
```

You should see:

```sh
ls -ld /rpool /rpool/inference-models
# drwxr-xr-x root root /rpool
# drwxr-xr-x root root /rpool/inference-models
```

Ollama will create its own layout under this mount.

### 2. Proxmox Directory Mapping

In the Proxmox web UI:

1. Datacenter → **Directory Mappings** → **Add**.
2. **ID**: `models`
3. **Node**: `pve-tomahawk`
4. **Path**: `/rpool/inference-models`
5. Save.

This defines the VirtioFS export the VMs will see.

### 3. Add VirtioFS device to the VM

For `inference1` (VM 103):

1. Select the VM → **Hardware** → **Add → VirtioFS**.
2. **Directory ID**: `models` (the mapping above).
3. Leave tag as `models` (this becomes the guest `device` name).
4. Apply changes.
5. **Fully power off**, then **start** the VM (VirtioFS device hotplug is unreliable).

You should now see a line like this in `/etc/pve/qemu-server/103.conf`:

```ini
virtiofs0: models
```

### 4. Host permissions for the shared directory

VirtioFS passes host permissions straight through. The guest cannot bypass them.

For debugging, we temporarily relaxed everything:

```sh
chmod 777 /rpool/inference-models
chmod -R 777 /rpool/inference-models/models
```

Long term, you should:

- Decide which UID/GID inside the guest owns the models (`ollama` in our case, usually uid 996).
- Ensure the host directory and its contents are writable by that uid/gid, or use ACLs:

```sh
chown -R 996:input /rpool/inference-models/models
chmod -R 770 /rpool/inference-models/models
# or use setfacl for finer control
```

Because VirtioFS does not virtualise permissions, any persistent "permission denied" must be fixed here (or via id‑mapping on the host), not just in the guest.

## NixOS guest (inference VM)

### 1. VirtioFS mount

In the NixOS host config (e.g. `hosts/nixos/inference-vm/hosts/inference1/default.nix` in this repo):

```nix
fileSystems."/models/ollama" = {
  device = "models"; # VirtioFS tag configured in Proxmox
  fsType = "virtiofs";
  options = [ "x-systemd.automount" "_netdev" ];
};
```

This matches the pattern from `virtualisation.rosetta` in nixpkgs: VirtioFS is just another filesystem; all the interesting work happens on the host.

After a rebuild and reboot, the guest should show:

```sh
mount | grep models
# models on /models/ollama type virtiofs ...
```

### 2. Ollama layout and tmpfiles

On the guest we treat `/models/ollama` as Ollama's "home" and ensure its layout is created with the right owner/mode.

Example (in `hosts/nixos/inference-vm/hosts/inference1/default.nix`):

```nix
users.users.ollama = {
  isSystemUser = true;
  group = "ollama";
  home = "/models/ollama";
};
users.groups.ollama = {};

systemd.services.ollama = {
  environment = {
    OLLAMA_MODELS = lib.mkForce "/models/ollama/models";
    HOME = lib.mkForce "/models/ollama";
  };
  serviceConfig = {
    StateDirectory = lib.mkForce "";
    DynamicUser = lib.mkForce false;
    ReadWritePaths = lib.mkForce [ "/models/ollama" ];
    WorkingDirectory = lib.mkForce "/models/ollama";
  };
};

systemd.tmpfiles.rules = [
  "d /models 0755 root root -"
  "d /models/ollama 0755 root root -"
  "Z /models/ollama/.ollama 0700 ollama ollama -"
  "Z /models/ollama/.ollama/id_ed25519 0600 ollama ollama -"
  "Z /models/ollama/.ollama/id_ed25519.pub 0644 ollama ollama -"
  # models tree under the VirtioFS mount
  "Z /models/ollama/models 0777 ollama ollama -"        # see note below
  "Z /models/ollama/models/blobs 0777 ollama ollama -"   # shared storage
  "Z /models/ollama/models/manifests 0777 ollama ollama -"
];
```

Notes:

- We currently use `0777` for the shared `models` subdirs while iterating on virtiofs id‑mapping; this is intentionally permissive. Once UID/GID mapping is nailed down, we can tighten this to `0770` or a more conservative mode.
- The **generic** version of these rules lives in `tesla-inference-flake` as a module option; here we override them specifically for inference VMs.

### 3. End‑to‑end check

On the guest (inference1):

```sh
ls -ld /models /models/ollama /models/ollama/models
ollama run llama3.1:8b
```

If you still see errors like `mkdir ... permission denied: ensure path elements are traversable` even with permissive modes, the problem is almost certainly on the host side (VirtioFS id‑mapping, ZFS ACLs, or Proxmox's Directory Mapping settings).

## Open issues / TODOs

- Refine host‑side UID/GID and ACL configuration so we can run with `0770` instead of `0777` on the shared models tree.
- Document a recommended id‑mapping strategy for VirtioFS in Proxmox once we've validated a clean setup on all inference VMs.
- Once the Ceph‑backed storage is ready, update this doc with the new dataset path but keep the same VirtioFS tag (`models`) and guest mountpoint (`/models/ollama`).
