# 3‑Node Inference Cluster Planning (Ceph + vLLM)

## Goals
- 3 Proxmox nodes with NVIDIA GPUs (e.g. P40 on `inference1`), running multi‑node inference (likely vLLM) with model sharding across ~72 GiB VRAM.
- Shared model storage across nodes using your pool of SSDs/NVMes.
- Dedicated 25 Gbps dual‑port Mellanox ring for storage and model traffic.
- NixOS/unified‑nix‑configuration modules/aspects to keep it reproducible.

---

## 1. Physical & Proxmox Topology

### 1.1 Nodes
- `inference1`, `inference2`, `inference3` (names to be finalized).
- Each: 1× NVIDIA GPU (P40 or similar), 1× NVMe (or SSD) allocated to Ceph, plus any extra SSDs you decide to attach.
- Proxmox VE on each node, using:
  - One network for general management/VM traffic.
  - One dedicated storage/model network on the Mellanox NICs.

### 1.2 Storage/Model Network
- Dual‑port Mellanox ConnectX‑4 per host.
- Topology: 25 Gbps ring (A↔B↔C↔A) dedicated to:
  - Ceph replication/erasure‑coding traffic.
  - Model distribution / vLLM RPC between nodes.
- NixOS module plan (for NixOS guests or future bare‑metal move):
  - `modules/nixos/network/inference-storage-net.nix`:
    - Configure dedicated interface or VLAN for `inference-net` (e.g. `10.20.0.0/24`).
    - Tune MTU (e.g. 9000 if end‑to‑end jumbo frames work).
    - Optionally set `sysctl` for TCP buffers for low‑latency, high‑throughput traffic.

---

## 2. Shared Model Storage Design

### 2.1 Ceph vs alternatives
- You already considered Linstor; Ceph with erasure coding is better for:
  - Spreading reads/writes across all SSDs.
  - Surviving single‑node failure.
  - Presenting a single namespace (CephFS) or block devices (RBD) to VMs.

### 2.2 Ceph topology
- 3‑node Ceph cluster, co‑located with Proxmox nodes.
- One Ceph MON+MGR per node (small overhead, simplifies quorum).
- OSDs:
  - Start with **one NVMe/SSD per node** as OSD; expand by adding remaining SSDs later.
  - Use separate Ceph pool(s) for models vs other data.

### 2.3 Pools and erasure coding
- Create a **models pool** optimized for capacity and read throughput:
  - Simplest: replicated size=3 (one replica per node) → robust, easy; higher capacity cost.
  - More advanced: EC (e.g. k=2, m=1) → tolerates 1 failure, better usable capacity.
- Consider starting with replication for simplicity, then migrate to EC once stable.

### 2.4 CephFS vs RBD for models
- **CephFS** (recommended for this use case):
  - Single POSIX filesystem mounted on each inference VM or NixOS host.
  - Simple for vLLM/ollama: models appear under a normal path (`/mnt/models`).
- **RBD** (optional):
  - Block device per VM; you’d put ext4/xfs on top and mount.
  - Slightly more management overhead, but fine if you want per‑VM volumes.

Plan: **CephFS `models` filesystem**, backed by the `models` pool.

---

## 3. NixOS / unified‑nix‑configuration Modules

### 3.1 Ceph cluster module
Create a Ceph cluster module group under `unified-nix-configuration/modules/nixos/ceph/`:

- `ceph-common.nix`:
  - Options:
    - `myModules.ceph.enable` (bool).
    - `myModules.ceph.clusterName` (default `ceph`).
    - `myModules.ceph.modelsPoolName` (default `models`).
    - `myModules.ceph.modelsFsName` (default `modelsfs`).
  - Shared config for all Ceph nodes (FSID, public network CIDR, etc.).

- `ceph-node.nix`:
  - Per‑host options:
    - `myModules.ceph.roles = [ "mon" "mgr" "osd" ]`.
    - `myModules.ceph.osdDevices = [ "/dev/nvme0n1" ]` (per host list).
  - Systemd services for MON/MGR/OSDs using NixOS’s Ceph module or custom if needed.
  - Networking bindings to `inference-net` for cluster traffic.

- `ceph-models-cephfs.nix`:
  - Declarative creation of `models` pool and `modelsfs` CephFS via `ceph.conf` + one‑shot units (or documented manual bootstrap steps).
  - Exposes options for pool type (replicated vs EC) and PG/PGP counts.

These modules are attached to **Proxmox hosts** if/when you manage them with NixOS, or to dedicated NixOS storage VMs that form the Ceph cluster.

### 3.2 Model mount module (guests / inference nodes)
New module `modules/nixos/inference-models-storage.nix`:

Options:
- `myModules.inferenceModels.enable`.
- `myModules.inferenceModels.type = "cephfs" | "virtiofs" | "nfs"` (future‑proof; start with `cephfs`).
- `myModules.inferenceModels.mountPoint = "/srv/models"` (or `/var/lib/models`).
- `myModules.inferenceModels.ceph.
    { monitors, fsName, mountOptions }`.

Behavior:
- Ensures required packages (`ceph`, `ceph-common`) are present.
- Adds a `fileSystems` entry for the CephFS mount:
  - Source: `ceph-fuse` or kernel client (`ceph:modelsfs`).
  - Target: `${cfg.mountPoint}`.
- Uses `tmpfiles.d` to enforce directory layout:
  - `${mountPoint}` root.
  - `${mountPoint}/models` for model weights.
  - Optionally `${mountPoint}/cache` for compiled artifacts.

Integrates with **tesla‑inference‑flake** modules by:
- Setting `tesla-inference.ollama.modelsPath = cfg.mountPoint` when both are enabled.
- Adding similar options for a future `vllm` or generic “inference engine” module.

### 3.3 Inference node module (vLLM ready)
New module `modules/nixos/inference-node.nix`:

Options:
- `myModules.inferenceNode.enable`.
- `myModules.inferenceNode.role = "gpu-worker" | "controller"`.
- `myModules.inferenceNode.modelsPath` (defaults to `myModules.inferenceModels.mountPoint`).
- `myModules.inferenceNode.engine = "ollama" | "vllm" | "both"`.

Behavior:
- Imports:
  - `tesla-inference-flake` NixOS module for Ollama when `engine` includes `ollama`.
  - Future vLLM module (you can stub this now) when `engine` includes `vllm`.
- Ensures:
  - GPU drivers + CUDA stack present (leveraging existing Tesla aspects).
  - `modelsPath` is mounted and permissions are sane (reusing tmpfiles patterns we already debugged).

This gives you a single knob to turn any NixOS host into an inference worker attached to shared models.

---

## 4. Host Definitions & Aspects

In `unified-nix-configuration/hosts/nixos/`:

- `inference1/default.nix`, `inference2/default.nix`, `inference3/default.nix`:
  - Import standard aspects: base, users, caches, Tesla GPU support.
  - Enable Ceph roles on the appropriate layer:
    - Either on bare‑metal NixOS (if you move off Proxmox), or
    - On dedicated `ceph-storage` VMs per node if you keep Proxmox as the hypervisor.
  - Enable `myModules.inferenceModels` and `myModules.inferenceNode` for guests that actually run vLLM/Ollama.

Use aspects like:
- `den/aspects/attic-cache-core.nix` and `den/aspects/nix-caches.nix` so all builders share Attic + nix-ci caches for heavy builds.

---

## 5. Phased Implementation Plan

1. **Baseline (done/ongoing)**
   - Stable single‑node inference on `inference1` with P40, shared models via VirtioFS or host path.
   - Tesla GPU stack + ollama working (we are here now).

2. **Ceph minimal cluster**
   - Stand up 3‑node Ceph with one OSD per host using NixOS modules.
   - Create replicated `models` pool and CephFS `modelsfs`.
   - Mount CephFS on one test VM and copy a few models.

3. **Model storage integration**
   - Implement `inference-models-storage.nix` and enable on `inference1` VM.
   - Point existing Ollama/vLLM configs at `/srv/models`.
   - Verify performance and permissions with current P40 workflows.

4. **Scale to 3‑node inference**
   - Define `inference2` and `inference3` hosts in flake.
   - Enable `myModules.inferenceNode` + `myModules.inferenceModels` on those VMs.
   - Use vLLM’s multi‑GPU / tensor parallel support to shard a model across GPUs/nodes, backed by the shared CephFS models path.

5. **Hardening and observability**
   - Add Ceph and GPU metrics into your existing monitoring (Prometheus exporters, Attic observatory).
   - Validate failure modes: node down, OSD down, Ceph degraded but serving; ensure inference continues.

6. **Optional refinements**
   - Move `models` pool from replication to erasure coding once comfortable with Ceph.
   - Add separate cache/metadata pools if you hit performance bottlenecks.
   - Layer higher‑level scheduler (Kubernetes, Nomad, or just systemd + simple controller) for vLLM deployment.

---

## 6. Next Steps

Short-term concrete tasks:
1. Add skeleton Ceph modules (`ceph-common.nix`, `ceph-node.nix`, `ceph-models-cephfs.nix`).
2. Add `inference-models-storage.nix` and wire it to tesla‑inference `modelsPath`.
3. Add `inference-node.nix` to bundle GPU + engine + storage config.
4. Define `inference2`/`inference3` host entries referencing these modules.

From there, we can start implementing the modules and iterating on details (exact Ceph pool parameters, vLLM service wiring, etc.).
