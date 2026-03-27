{ pkgs }:

{
  mkService =
    {
      # Human-readable systemd unit description.
      description,
      # Podman container name to inspect for its current bridge-network IP.
      containerName,
      # Systemd unit that owns the container lifecycle. Defaults to the oci-container unit.
      containerService ? "podman-${containerName}.service",
      # Host port exposed for LAN/admin access. This is intentionally distinct from the
      # container port so host-side debug/admin ports do not collide with app defaults.
      hostPort,
      # Port the app actually listens on inside the container network namespace.
      containerPort,
    }:
    let
      podman = "${pkgs.podman}/bin/podman";
      socat = "${pkgs.socat}/bin/socat";
      shell = "${pkgs.runtimeShell}";
    in
    {
      inherit description;
      after = [ "network-online.target" containerService ];
      wants = [ "network-online.target" containerService ];
      wantedBy = [ "multi-user.target" ];
      partOf = [ containerService ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 2;
        ExecStartPre =
          "${shell} -c 'for _ in $(seq 1 30); do target_ip=$(${podman} inspect ${containerName} --format \"{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\" 2>/dev/null || true); if [ -n \"$${target_ip}\" ]; then exit 0; fi; sleep 1; done; echo \"${containerName} IP not available\" >&2; exit 1'";
        ExecStart =
          "${shell} -c 'set -eu; target_ip=$(${podman} inspect ${containerName} --format \"{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\"); exec ${socat} TCP-LISTEN:${toString hostPort},reuseaddr,fork,bind=0.0.0.0 TCP:$${target_ip}:${toString containerPort}'";
      };
    };
}
