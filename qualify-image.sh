#!/usr/bin/env bash
set -euo pipefail
out=${1:?Usage: qualify-image.sh BUILD_OUTPUT_DIRECTORY}
iso_dir="$out/image/grml_isos"
test -d "$iso_dir" || { echo "No grml-live ISO output" >&2; exit 2; }
mapfile -t isos < <(find "$iso_dir" -maxdepth 1 -type f -name '*.iso')
test "${#isos[@]}" -eq 1 || { echo "Expected exactly one ISO" >&2; exit 2; }
command -v xorriso >/dev/null || { echo "xorriso required" >&2; exit 2; }
command -v qemu-system-aarch64 >/dev/null || { echo "qemu-system-aarch64 required" >&2; exit 2; }
xorriso -indev "${isos[0]}" -report_el_torito plain
sha256sum "${isos[0]}"
echo "PASS: image exists and optical boot metadata inspected."
echo "NOT QUALIFIED: QEMU ARM64 boot, systemd readiness, rootless Podman, DNS, and Nginx."
