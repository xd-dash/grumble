#!/usr/bin/env bash
set -euo pipefail

out=${1:?Usage: boot-qemu.sh BUILD_OUTPUT_DIR [FIRMWARE_CODE_FD]}
firmware=${2:-${AAVMF_CODE:-}}
[[ -n "$firmware" && -f "$firmware" ]] || {
  echo "Supply ARM64 UEFI firmware as second argument or AAVMF_CODE" >&2; exit 2;
}
command -v qemu-system-aarch64 >/dev/null || { echo "Missing qemu-system-aarch64" >&2; exit 2; }
mapfile -t isos < <(find "$out/image/grml_isos" -maxdepth 1 -type f -name '*.iso' | sort)
[[ ${#isos[@]} -eq 1 ]] || { echo "Expected exactly one ISO" >&2; exit 2; }
qemu-system-aarch64 \
  -machine virt,accel=tcg -cpu cortex-a72 -smp 2 -m 2048 \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware" \
  -device virtio-scsi-pci \
  -drive "if=none,id=cdrom,media=cdrom,readonly=on,file=${isos[0]}" \
  -device scsi-cd,drive=cdrom \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -nographic -no-reboot
