#!/usr/bin/env bash
# Quick helper to rerun Hyprland with verbose logging and capture output.

set -euo pipefail

timestamp="$(date +%Y%m%d-%H%M%S)"
out_dir="/tmp/hyprland-debug-${timestamp}"
mkdir -p "${out_dir}"

cfg="${HOME}/.config/hypr/hyprland.conf"
tmp_cfg="${out_dir}/hyprland.conf"

if [[ -f "${cfg}" ]]; then
  cp "${cfg}" "${tmp_cfg}"
  chmod u+w "${tmp_cfg}"
  if grep -q '^[[:space:]]*debug:disable_logs' "${tmp_cfg}"; then
    sed -i 's/^[[:space:]]*debug:disable_logs.*/debug:disable_logs = false/' "${tmp_cfg}"
  else
    printf '\n# Added by hyprland-debug.sh\ndebug:disable_logs = false\n' >> "${tmp_cfg}"
  fi
else
  echo "Config not found at ${cfg}; continuing without custom config"
  tmp_cfg="${cfg}"
fi

echo "Output directory: ${out_dir}"
echo "Using config: ${tmp_cfg}"
echo "Launching Hyprland; this will block until it exits..."

env \
  HYPRLAND_LOG_WLR=1 \
  HYPRLAND_LOG_WLR_LEVEL=DEBUG \
  HYPRLAND_NO_LOG_COLORS=1 \
  HYPRLAND_INSTANCE_SIGNATURE="debugtty" \
  Hyprland --config "${tmp_cfg}" &> "${out_dir}/hyprland.log"

echo
echo "Hyprland exited. Log saved to ${out_dir}/hyprland.log"
