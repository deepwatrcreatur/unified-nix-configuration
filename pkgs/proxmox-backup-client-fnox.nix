{
  lib,
  symlinkJoin,
  writeShellApplication,
  proxmox-backup-client,
  fnox,
}:
let
  wrapped = writeShellApplication {
    name = "proxmox-backup-client-fnox";

    runtimeInputs = [
      proxmox-backup-client
      fnox
    ];

    text = ''
      # Inject PBS_PASSWORD if not already set
      if [ -z "''${PBS_PASSWORD:-}" ]; then
        password="$(fnox get PBS_PASSWORD 2>/dev/null || true)"
        if [ -n "$password" ]; then
          export PBS_PASSWORD="$password"
        fi
      fi

      # Inject PBS_REPOSITORY if not already set
      if [ -z "''${PBS_REPOSITORY:-}" ]; then
        repo="$(fnox get PBS_REPOSITORY 2>/dev/null || true)"
        if [ -n "$repo" ]; then
          export PBS_REPOSITORY="$repo"
        fi
      fi

      exec proxmox-backup-client "$@"
    '';
  };
in
symlinkJoin {
  name = "proxmox-backup-client-fnox";
  paths = [ wrapped ];

  postBuild = ''
    ln -s "$out/bin/proxmox-backup-client-fnox" "$out/bin/proxmox-backup-client"
  '';

  meta = {
    description = "Proxmox Backup Client wrapper that sources PBS_PASSWORD and PBS_REPOSITORY via fnox";
    homepage = "https://www.proxmox.com/en/proxmox-backup-server";
    mainProgram = "proxmox-backup-client";
    platforms = proxmox-backup-client.meta.platforms or lib.platforms.all;
  };
}
